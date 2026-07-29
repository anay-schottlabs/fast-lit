import Foundation
import Observation
import FirebaseAuth
import FirebaseFirestore

// Wraps FirebaseAuth so the rest of the app talks to this instead of the
// Auth SDK directly — one place to change later if the auth approach
// evolves. Wired into LibraryLoginView/LibrarySignUpView via
// @Environment(AuthService.self); ios_accessibleApp owns the one instance
// and hands it down to every view with .environment(). Reader accounts
// don't use this yet — they're still six-digit-code placeholders.
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

    // Convenience for views that need their own uid (e.g.
    // LibraryCatalogManagementView, to fetch its own enabled catalog
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
    // Library sign-up) build a fixed-domain pseudo-email from it rather
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

    // MARK: - Library username registry

    // Firestore doc IDs double as a uniqueness registry: each library
    // username gets one doc at libraryUsernames/{username}, and its mere
    // existence means that username is taken. This exists because Firebase
    // Auth's own equivalent check — fetchSignInMethods(forEmail:) — always
    // returns an empty array on projects with email enumeration protection
    // enabled (the Firebase-recommended, more secure default), making it
    // useless for exactly this "is it taken" question. The actual Auth
    // account (created in signUp above) remains the real, atomic
    // uniqueness guarantee; this registry only powers the early "already
    // taken" check on the sign-up username step, before an account exists
    // to check against.
    private var libraryUsernames: CollectionReference {
        Firestore.firestore().collection("libraryUsernames")
    }

    /// Checks whether a library username is already registered.
    func isUsernameTaken(_ username: String) async throws -> Bool {
        let document = try await libraryUsernames.document(username).getDocument()
        return document.exists
    }

    /// Registers a username as taken so later sign-ups see it via
    /// `isUsernameTaken`.
    // Registers a username as taken, so later sign-ups see it via
    // isUsernameTaken. Only meaningful to call after the matching Firebase
    // Auth account was actually created — see the signUp caller's comment
    // in LibrarySignUpView for why a failure here shouldn't block that
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
        try await libraryUsernames.document(username).setData([
            "uid": Auth.auth().currentUser?.uid ?? "",
            "createdAt": FieldValue.serverTimestamp(),
        ])
    }

    // MARK: - Library profile

    /// Generates a random `XXX-XXX` join code for a new library account.
    // Generates a join code readers use to find and sign up for a specific
    // library: 3 random letters/digits, a hyphen, then 3 more (e.g.
    // "AB3-9F2"). Uppercase-only so it isn't case-sensitive to whoever
    // types it back in later. A static, Firebase-independent function
    // (rather than something that reaches into Firestore itself) since
    // generating the code and persisting it are separate concerns — this
    // just produces the string; createLibraryProfile below is what saves it.
    static func generateJoinCode() -> String {
        let characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        func randomTriplet() -> String {
            String((0..<3).map { _ in characters.randomElement()! })
        }
        return "\(randomTriplet())-\(randomTriplet())"
    }

    // A library account's own profile — the data LibraryHomeView reads back
    // to display "your join code", as opposed to libraryUsernames above,
    // which exists purely for the sign-up uniqueness check.
    /// A library account's saved username + join code.
    struct LibraryProfile {
        let username: String
        let joinCode: String
    }

    // Keyed by uid (not username, unlike libraryUsernames) since this is
    // "my own profile" data, read back by the signed-in owner via their own
    // uid rather than looked up by name.
    private var libraries: CollectionReference {
        Firestore.firestore().collection("libraries")
    }

    // Saves a library account's profile (username + join code) right after
    // sign-up. Only meaningful once the Auth account exists — see
    // registerUsername above for why Auth.auth().currentUser is read fresh
    // here rather than this class's own (possibly not-yet-updated)
    // currentUser property.
    /// Saves a new library account's profile plus its join-code lookup entry.
    func createLibraryProfile(username: String, libraryName: String, joinCode: String) async throws {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        try await libraries.document(uid).setData([
            "username": username,
            "joinCode": joinCode,
            "createdAt": FieldValue.serverTimestamp(),
        ])
        // A second, join-code-keyed registry so a reader (who has no
        // account and never signs in) can look up which library a code
        // belongs to with a plain get-by-ID — the same trick libraryUsernames
        // uses for the sign-up "is this taken" check, applied here instead
        // to "what's this code" lookups.
        try await libraryJoinCodes.document(joinCode).setData([
            "uid": uid,
            "libraryName": libraryName,
            "createdAt": FieldValue.serverTimestamp(),
        ])
    }

    // Keyed by join code (not uid) so a reader — who has no account at all —
    // can resolve a typed-in code straight to the library's name via a
    // single get-by-ID, no auth or query required.
    private var libraryJoinCodes: CollectionReference {
        Firestore.firestore().collection("libraryJoinCodes")
    }

    // MARK: - Join codes

    // What ReaderAccountView gets back from a successful join-code lookup —
    // both the name (to show "You've Joined ___") and the uid (so ChooseView
    // knows whose libraryCatalogSelections to filter the catalog against).
    /// A library resolved from a reader-typed join code.
    struct JoinedLibrary {
        let uid: String
        let name: String
    }

    /// Resolves a reader-typed join code to the library it belongs to.
    func fetchJoinedLibrary(forJoinCode joinCode: String) async throws -> JoinedLibrary? {
        let document = try await libraryJoinCodes.document(joinCode).getDocument()
        guard let uid = document.get("uid") as? String,
              let libraryName = document.get("libraryName") as? String else {
            return nil
        }
        return JoinedLibrary(uid: uid, name: libraryName)
    }

    // MARK: - Catalog

    // The shared reading catalog every library draws from — see
    // scripts/import-catalog.js, the one-off admin script that's the only
    // thing that ever writes here (see firestore.rules: clients can only
    // read this collection, never write it).
    private var catalog: CollectionReference {
        Firestore.firestore().collection("catalog")
    }

    // Fetches every item in the catalog. Used both by ChooseView (which
    // filters this down to whatever the reader's joined library has
    // enabled) and by LibraryCatalogManagementView (which needs every item
    // to build its toggle list).
    /// Fetches every item in the shared catalog.
    func fetchCatalog() async throws -> [ReadableContent] {
        let snapshot = try await catalog.getDocuments()
        return snapshot.documents.compactMap { document in
            guard let title = document.get("title") as? String,
                  let description = document.get("description") as? String,
                  let text = document.get("text") as? String else {
                return nil
            }
            return ReadableContent(id: document.documentID, title: title, description: description, text: text, source: .library, sourceURL: nil)
        }
    }

    // MARK: - Library catalog selections

    // Keyed by library uid (not the library's own doc under libraries/{uid})
    // since this needs to be publicly readable — a reader who just joined
    // by code has no account and never signs in, but still needs to know
    // which catalog items that library enabled.
    private var libraryCatalogSelections: CollectionReference {
        Firestore.firestore().collection("libraryCatalogSelections")
    }

    // Which catalog items a library has enabled for its readers. A missing
    // doc (a library that's never visited its catalog management screen
    // yet) means none are enabled yet, not an error.
    /// Which catalog items a library has enabled for its readers.
    func fetchEnabledContentIds(forLibraryUid uid: String) async throws -> Set<String> {
        let document = try await libraryCatalogSelections.document(uid).getDocument()
        guard let ids = document.get("enabledContentIds") as? [String] else {
            return []
        }
        return Set(ids)
    }

    // Saves which catalog items the signed-in library's readers may
    // access, replacing the entire enabled set each time rather than
    // patching it incrementally — simplest to reason about for a toggle
    // list this small.
    /// Replaces the signed-in library's entire enabled-content set.
    func setEnabledContentIds(_ ids: Set<String>) async throws {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        try await libraryCatalogSelections.document(uid).setData([
            "enabledContentIds": Array(ids),
            "updatedAt": FieldValue.serverTimestamp(),
        ])
    }

    // Reads the signed-in library account's own profile. nil means there's
    // no profile doc yet (e.g. createLibraryProfile failed silently during
    // sign-up) rather than an error — LibraryHomeView treats those
    // differently.
    /// Reads the signed-in library account's own profile.
    func fetchLibraryProfile() async throws -> LibraryProfile? {
        guard let uid = Auth.auth().currentUser?.uid else { return nil }
        let document = try await libraries.document(uid).getDocument()
        guard let username = document.get("username") as? String,
              let joinCode = document.get("joinCode") as? String else {
            return nil
        }
        return LibraryProfile(username: username, joinCode: joinCode)
    }

    // MARK: - Reader (anonymous) auth

    // Signs in with no credentials at all — Firebase still issues a real
    // (if anonymous) account. One way Reader accounts (just a six-digit
    // code, no username/password) could eventually be handled.
    /// Signs in with no credentials, issuing a real anonymous Firebase account.
    func signInAnonymously() async throws {
        _ = try await Auth.auth().signInAnonymously()
    }

    // Readers otherwise have no Firebase Auth session at all (see this
    // file's own top comment) — this is what actually creates their
    // first (anonymous) one, called lazily the first time saved content
    // needs somewhere to live rather than up front at app launch, since
    // most of a reader's time in the app (picking library content,
    // reading it) never touches savedContent at all. Anonymous sign-in
    // persists across launches on the same device via Firebase's own
    // keychain-backed session, so a reader's saved content survives
    // relaunches without them ever seeing a login screen. A no-op if
    // already signed in (anonymously or otherwise) — never overwrites an
    // existing session with a fresh anonymous one.
    /// Lazily creates a reader's first (anonymous) session, if none exists yet.
    func ensureReaderSignedIn() async throws {
        guard Auth.auth().currentUser == nil else { return }
        try await signInAnonymously()
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
