import Foundation
import Observation
import FirebaseAuth

// Wraps FirebaseAuth so the rest of the app talks to this instead of the
// Auth SDK directly — one place to change later if the auth approach
// evolves. Wired into LibraryLoginView/LibrarySignUpView via
// @Environment(AuthService.self); ios_accessibleApp owns the one instance
// and hands it down to every view with .environment(). Reader accounts
// don't use this yet — they're still six-digit-code placeholders.
@Observable
class AuthService {
    // Mirrors Firebase's own signed-in state. nil means signed out.
    private(set) var currentUser: User?

    // Convenience for views that only care whether someone's signed in,
    // not who.
    var isSignedIn: Bool {
        currentUser != nil
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

    // Signs into an existing email/password account.
    func signIn(email: String, password: String) async throws {
        _ = try await Auth.auth().signIn(withEmail: email, password: password)
    }

    // Signs in with no credentials at all — Firebase still issues a real
    // (if anonymous) account. One way Reader accounts (just a six-digit
    // code, no username/password) could eventually be handled.
    func signInAnonymously() async throws {
        _ = try await Auth.auth().signInAnonymously()
    }

    func signOut() throws {
        try Auth.auth().signOut()
    }
}
