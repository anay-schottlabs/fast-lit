import Foundation
import Observation
import FirebaseAuth

// Wraps FirebaseAuth so the rest of the app talks to this instead of the
// Auth SDK directly — one place to change later if the auth approach
// evolves. Not wired into any login/signup screen yet; that's a separate
// step. ios_accessibleApp owns the one instance and hands it down via
// .environment(), so views will eventually read it with
// @Environment(AuthService.self).
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
    // on email, not a plain username — how Library sign-up's "username"
    // field eventually maps to this is a decision for whenever that screen
    // itself gets wired up to call this.
    func signUp(email: String, password: String) async throws {
        _ = try await Auth.auth().createUser(withEmail: email, password: password)
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
