import Foundation
import Observation
import FirebaseAuth
import FirebaseFirestore

// Wraps FirebaseAuth so the rest of the app talks to this instead of the
// Auth SDK directly — one place to change later if the auth approach
// evolves. Wired into OrganizerLoginView/OrganizerSignUpView via
// @Environment(AuthService.self); ios_accessibleApp owns the one instance
// and hands it down to every view with .environment(). Reader accounts
// use Firebase's anonymous auth instead (see ensureReaderSignedIn below),
// not a username/password of their own.
/// The app's single Firebase Auth + Firestore access point — one
/// `@Observable` instance, handed down the view tree via `.environment()`.
@Observable
class AuthService {
    // MARK: - Sign-in state

    // Mirrors Firebase's own signed-in state. nil means signed out.
    private(set) var currentUser: User?

    // Convenience for views that only care whether someone's signed in,
    // not who.
    var isSignedIn: Bool {
        currentUser != nil
    }

    // An anonymous reader session (see ensureReaderSignedIn) also makes
    // currentUser non-nil, so plain isSignedIn above can't tell "a real
    // organizer account" apart from "a reader who's shared/saved
    // something before." AccountView needs that distinction to route a
    // returning visitor to the right flow — without it, a reader with an
    // anonymous session was being misrouted into the organizer sign-
    // in/sign-up flow (which has no profile for their uid) instead of
    // their own reader home.
    var isOrganizerSignedIn: Bool {
        guard let currentUser else { return false }
        return !currentUser.isAnonymous
    }

    // The reader-flow counterpart to isOrganizerSignedIn just above — true
    // once ensureReaderSignedIn has run at least once on this device, so
    // AccountView can skip straight to ReaderAccountView's own home
    // content on a later visit instead of asking "who's joining us?"
    // again.
    var isReaderSignedIn: Bool {
        guard let currentUser else { return false }
        return currentUser.isAnonymous
    }

    // Convenience for views that need their own uid (e.g.
    // OrganizerCatalogManagementView, to fetch its own enabled catalog
    // selections) without importing FirebaseAuth themselves just to read
    // one property off currentUser's User type.
    var currentUserUid: String? {
        currentUser?.uid
    }

    // Firebase calls this any time sign-in state changes (sign in, sign
    // out, token refresh) — keeps currentUser in sync without this class
    // having to poll or guess.
    private var authStateListenerHandle: AuthStateDidChangeListenerHandle?

    init() {
        currentUser = Auth.auth().currentUser
        authStateListenerHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.currentUser = user
        }
    }

    deinit {
        if let authStateListenerHandle {
            Auth.auth().removeStateDidChangeListener(authStateListenerHandle)
        }
    }

    // MARK: - Email/password auth

    /// Creates a brand-new email/password Firebase Auth account.
    // Creates a brand-new account. Firebase Auth's built-in strategies key
    // on email, not a plain username — callers with only a username (like
    // Organizer sign-up) build a fixed-domain pseudo-email from it rather
    // than this class needing to know about that mapping.
    // displayName is optional since not every caller has one to set (e.g.
    // Reader sign-up, which asks for a name but nothing else this shares).
    func signUp(email: String, password: String, displayName: String? = nil) async throws {
        let result = try await Auth.auth().createUser(withEmail: email, password: password)

        if let displayName {
            let changeRequest = result.user.createProfileChangeRequest()
            changeRequest.displayName = displayName
            try await changeRequest.commitChanges()
        }
    }

    /// Signs into an existing email/password account.
    func signIn(email: String, password: String) async throws {
        _ = try await Auth.auth().signIn(withEmail: email, password: password)
    }

    // MARK: - Circle username registry

    // Firestore doc IDs double as a uniqueness registry: each organizer's
    // circle username gets one doc at circleUsernames/{username}, and its
    // mere existence means that username is taken. This exists because
    // Firebase Auth's own equivalent check — fetchSignInMethods(forEmail:) —
    // always returns an empty array on projects with email enumeration
    // protection enabled (the Firebase-recommended, more secure default),
    // making it useless for exactly this "is it taken" question. The
    // actual Auth account (created in signUp above) remains the real,
    // atomic uniqueness guarantee; this registry only powers the early
    // "already taken" check on the sign-up username step, before an
    // account exists to check against.
    private var circleUsernames: CollectionReference {
        Firestore.firestore().collection("circleUsernames")
    }

    /// Checks whether a circle username is already registered.
    func isUsernameTaken(_ username: String) async throws -> Bool {
        let document = try await circleUsernames.document(username).getDocument()
        return document.exists
    }

    /// Registers a username as taken so later sign-ups see it via
    /// `isUsernameTaken`.
    // Only meaningful to call after the matching Firebase Auth account was
    // actually created — see the signUp caller's comment in
    // OrganizerSignUpView for why a failure here shouldn't block that
    // already-successful sign-up.
    //
    // Reads Auth.auth().currentUser directly here rather than this class's
    // own currentUser property: that property only updates once Firebase's
    // addStateDidChangeListener callback fires, which isn't guaranteed to
    // have happened yet by the time this runs (immediately after signUp()
    // returns) — writing self.currentUser?.uid could send an empty string
    // as uid while Firestore's own request.auth.uid (evaluated fresh,
    // against the real current session) is already the new account's real
    // ID, failing the security rule that requires them to match.
    func registerUsername(_ username: String) async throws {
        try await circleUsernames.document(username).setData([
            "uid": Auth.auth().currentUser?.uid ?? "",
            "createdAt": FieldValue.serverTimestamp(),
        ])
    }

    // MARK: - Circle profile

    /// Generates a random `XXX-XXX` join code for a new circle.
    // Generates a join code readers use to find and join a specific
    // circle: 3 random letters/digits, a hyphen, then 3 more (e.g.
    // "AB3-9F2"). Uppercase-only so it isn't case-sensitive to whoever
    // types it back in later. A static, Firebase-independent function
    // (rather than something that reaches into Firestore itself) since
    // generating the code and persisting it are separate concerns — this
    // just produces the string; createCircleProfile below is what saves it.
    static func generateJoinCode() -> String {
        let characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        func randomTriplet() -> String {
            String((0..<3).map { _ in characters.randomElement()! })
        }
        return "\(randomTriplet())-\(randomTriplet())"
    }

    // A circle's own profile — the data OrganizerHomeView reads back to
    // display "your join code", as opposed to circleUsernames above,
    // which exists purely for the sign-up uniqueness check.
    /// An organizer's saved username + their circle's join code.
    struct CircleProfile {
        let username: String
        let joinCode: String
    }

    // Keyed by uid (not username, unlike circleUsernames) since this is
    // "my own profile" data, read back by the signed-in owner via their own
    // uid rather than looked up by name.
    private var circles: CollectionReference {
        Firestore.firestore().collection("circles")
    }

    // Saves an organizer's circle profile (username + join code) right
    // after sign-up. Only meaningful once the Auth account exists — see
    // registerUsername above for why Auth.auth().currentUser is read fresh
    // here rather than this class's own (possibly not-yet-updated)
    // currentUser property.
    /// Saves a new circle's profile plus its join-code lookup entry.
    func createCircleProfile(username: String, circleName: String, joinCode: String) async throws {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        try await circles.document(uid).setData([
            "username": username,
            "joinCode": joinCode,
            "createdAt": FieldValue.serverTimestamp(),
        ])
        // A second, join-code-keyed registry so a reader (who has no
        // account and never signs in with a password) can look up which
        // circle a code belongs to with a plain get-by-ID — the same
        // trick circleUsernames uses for the sign-up "is this taken"
        // check, applied here instead to "what's this code" lookups.
        try await circleJoinCodes.document(joinCode).setData([
            "uid": uid,
            "circleName": circleName,
            "createdAt": FieldValue.serverTimestamp(),
        ])
    }

    // Keyed by join code (not uid) so a reader — who has no account at all —
    // can resolve a typed-in code straight to the circle's name via a
    // single get-by-ID, no auth or query required.
    private var circleJoinCodes: CollectionReference {
        Firestore.firestore().collection("circleJoinCodes")
    }

    // MARK: - Join codes

    // What ReaderAccountView gets back from a successful join-code lookup —
    // both the name (for its circle list) and the uid (so ChooseView knows
    // whose circleCatalogSelections to filter the catalog against).
    /// A circle resolved from a reader-typed join code.
    struct JoinedCircle {
        let uid: String
        let name: String
    }

    /// Resolves a reader-typed join code to the circle it belongs to.
    func fetchJoinedCircle(forJoinCode joinCode: String) async throws -> JoinedCircle? {
        let document = try await circleJoinCodes.document(joinCode).getDocument()
        guard let uid = document.get("uid") as? String,
              let circleName = document.get("circleName") as? String else {
            return nil
        }
        return JoinedCircle(uid: uid, name: circleName)
    }

    // MARK: - Catalog

    // The shared reading catalog every circle draws from — see
    // scripts/import-catalog.js, the one-off admin script that's the only
    // thing that ever writes here (see firestore.rules: clients can only
    // read this collection, never write it).
    private var catalog: CollectionReference {
        Firestore.firestore().collection("catalog")
    }

    // Fetches every item in the catalog. Used both by ChooseView (which
    // filters this down to whatever each of a reader's joined circles has
    // enabled) and by OrganizerCatalogManagementView (which needs every
    // item to build its toggle list).
    /// Fetches every item in the shared catalog.
    func fetchCatalog() async throws -> [ReadableContent] {
        let snapshot = try await catalog.getDocuments()
        return snapshot.documents.compactMap { document in
            guard let title = document.get("title") as? String,
                  let description = document.get("description") as? String,
                  let text = document.get("text") as? String else {
                return nil
            }
            return ReadableContent(id: document.documentID, title: title, description: description, text: text, source: .catalog, sourceURL: nil)
        }
    }

    // MARK: - Circle catalog selections

    // Keyed by circle uid (not the circle's own doc under circles/{uid})
    // since this needs to be publicly readable — a reader who just joined
    // by code has no account and never signs in, but still needs to know
    // which catalog items that circle enabled.
    private var circleCatalogSelections: CollectionReference {
        Firestore.firestore().collection("circleCatalogSelections")
    }

    // Which catalog items a circle has enabled for its readers. A missing
    // doc (a circle that's never visited its catalog management screen
    // yet) means none are enabled yet, not an error.
    /// Which catalog items a circle has enabled for its readers.
    func fetchEnabledContentIds(forCircleUid uid: String) async throws -> Set<String> {
        let document = try await circleCatalogSelections.document(uid).getDocument()
        guard let ids = document.get("enabledContentIds") as? [String] else {
            return []
        }
        return Set(ids)
    }

    // Saves which catalog items the signed-in organizer's circle members
    // may access, replacing the entire enabled set each time rather than
    // patching it incrementally — simplest to reason about for a toggle
    // list this small.
    /// Replaces the signed-in organizer's entire enabled-content set.
    func setEnabledContentIds(_ ids: Set<String>) async throws {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        try await circleCatalogSelections.document(uid).setData([
            "enabledContentIds": Array(ids),
            "updatedAt": FieldValue.serverTimestamp(),
        ])
    }

    // Reads the signed-in organizer's own circle profile. nil means
    // there's no profile doc yet (e.g. createCircleProfile failed
    // silently during sign-up) rather than an error — OrganizerHomeView
    // treats those differently.
    /// Reads the signed-in organizer's own circle profile.
    func fetchCircleProfile() async throws -> CircleProfile? {
        guard let uid = Auth.auth().currentUser?.uid else { return nil }
        let document = try await circles.document(uid).getDocument()
        guard let username = document.get("username") as? String,
              let joinCode = document.get("joinCode") as? String else {
            return nil
        }
        return CircleProfile(username: username, joinCode: joinCode)
    }

    // MARK: - Reader (anonymous) auth

    // Signs in with no credentials at all — Firebase still issues a real
    // (if anonymous) account. How Reader accounts are identified: no
    // username/password of their own, just a per-device session.
    /// Signs in with no credentials, issuing a real anonymous Firebase account.
    func signInAnonymously() async throws {
        _ = try await Auth.auth().signInAnonymously()
    }

    // Readers otherwise have no Firebase Auth session at all — this is
    // what actually creates their first (anonymous) one. Called lazily
    // the first time a reader needs somewhere for their own data to live
    // (saved content, joined circles) rather than up front at app
    // launch, since a reader who's only browsing never strictly needs an
    // account. Anonymous sign-in persists across launches on the same
    // device via Firebase's own keychain-backed session, so a reader's
    // saved content and joined circles survive relaunches without them
    // ever seeing a login screen. A no-op if already signed in
    // (anonymously or otherwise) — never overwrites an existing session
    // with a fresh anonymous one.
    /// Lazily creates a reader's first (anonymous) session, if none exists yet.
    func ensureReaderSignedIn() async throws {
        guard Auth.auth().currentUser == nil else { return }
        try await signInAnonymously()
    }

    // MARK: - Reader circle memberships

    // A reader's own list of joined circles — shown on ReaderAccountView's
    // home page, and used by ChooseView to build one catalog section per
    // circle. Keyed by circle uid under the reader's own uid (not a flat
    // collection queried by reader) since a reader only ever needs their
    // own full list, never anyone else's, and this shape also makes
    // joining a circle a second time a harmless overwrite of the same
    // doc rather than a duplicate. nil when there's no signed-in reader
    // yet, mirroring savedContent below.
    private var joinedCircles: CollectionReference? {
        guard let uid = Auth.auth().currentUser?.uid else { return nil }
        return Firestore.firestore().collection("readers").document(uid).collection("joinedCircles")
    }

    /// A circle a reader has joined, as shown on their home page.
    struct JoinedCircleMembership: Identifiable {
        let id: String
        let name: String
    }

    /// Every circle the signed-in reader has joined.
    func fetchJoinedCircles() async throws -> [JoinedCircleMembership] {
        guard let joinedCircles else { return [] }
        let snapshot = try await joinedCircles.getDocuments()
        return snapshot.documents.compactMap { document in
            guard let circleName = document.get("circleName") as? String else {
                return nil
            }
            return JoinedCircleMembership(id: document.documentID, name: circleName)
        }
    }

    // Doc ID is the circle's own uid — see joinedCircles above for why
    // that makes joining an already-joined circle a safe, idempotent
    // overwrite rather than a duplicate membership.
    /// Records that the signed-in reader has joined `circle`.
    func recordJoinedCircle(_ circle: JoinedCircle) async throws {
        guard let joinedCircles else { return }
        try await joinedCircles.document(circle.uid).setData([
            "circleName": circle.name,
            "joinedAt": FieldValue.serverTimestamp(),
        ])
    }

    // MARK: - Saved content

    // A reader's own saved content — shared articles that persist past
    // the single reading session they were shared into, scoped to their
    // own (anonymous) account via ensureReaderSignedIn above. nil when
    // there's no signed-in reader yet, which fetchSavedContent/
    // findSavedContent/saveContent below all treat as "nothing saved"
    // rather than an error, since a reader who's never shared anything
    // yet has no session at all until they do.
    private var savedContent: CollectionReference? {
        guard let uid = Auth.auth().currentUser?.uid else { return nil }
        return Firestore.firestore().collection("readers").document(uid).collection("savedContent")
    }

    // Every article the signed-in reader has saved, for ChooseView's own
    // "Saved" section.
    /// Every article the signed-in reader has saved.
    func fetchSavedContent() async throws -> [ReadableContent] {
        guard let savedContent else { return [] }
        let snapshot = try await savedContent.getDocuments()
        return snapshot.documents.compactMap { document in
            guard let title = document.get("title") as? String,
                  let description = document.get("description") as? String,
                  let text = document.get("text") as? String,
                  let sourceURL = document.get("sourceURL") as? String else {
                return nil
            }
            return ReadableContent(id: document.documentID, title: title, description: description, text: text, source: .saved, sourceURL: sourceURL)
        }
    }

    // Looks for a saved item matching this exact source URL, so a reader
    // sharing the same article a second time reopens what's already
    // there (see ContentView's own pendingSharedURL handling) instead of
    // silently creating a duplicate entry every time.
    /// Looks for an already-saved item matching this exact source URL, for dedup.
    func findSavedContent(bySourceURL sourceURL: String) async throws -> ReadableContent? {
        guard let savedContent else { return nil }
        let snapshot = try await savedContent
            .whereField("sourceURL", isEqualTo: sourceURL)
            .limit(to: 1)
            .getDocuments()
        guard let document = snapshot.documents.first,
              let title = document.get("title") as? String,
              let description = document.get("description") as? String,
              let text = document.get("text") as? String else {
            return nil
        }
        return ReadableContent(id: document.documentID, title: title, description: description, text: text, source: .saved, sourceURL: sourceURL)
    }

    // Persists a newly-extracted shared article to the signed-in
    // reader's own saved content — content.id becomes the doc ID, so
    // re-saving the same ReadableContent value (shouldn't normally
    // happen, since findSavedContent above is checked first) overwrites
    // rather than duplicates.
    /// Persists a newly-extracted shared article to the signed-in reader's saved content.
    func saveContent(_ content: ReadableContent, sourceURL: String) async throws {
        guard let savedContent else { return }
        try await savedContent.document(content.id).setData([
            "title": content.title,
            "description": content.description,
            "text": content.text,
            "sourceURL": sourceURL,
            "createdAt": FieldValue.serverTimestamp(),
        ])
    }

    // MARK: - Sign out

    /// Signs the current user out.
    func signOut() throws {
        try Auth.auth().signOut()
    }
}
