import SwiftUI
import FirebaseCore

@main
struct ios_accessibleApp: App {
    // Owns the one AuthService for the app's lifetime; handed down to every
    // view via .environment so nothing has to create its own instance. Not
    // read anywhere yet — that's for whenever the login/signup screens get
    // wired up to it.
    @State private var authService: AuthService

    // A custom init (rather than a plain "= AuthService()" default above)
    // so FirebaseApp.configure() is guaranteed to run before AuthService's
    // own init, which touches Auth.auth() and crashes if Firebase isn't
    // configured yet. This isn't hypothetical: an AppDelegate +
    // @UIApplicationDelegateAdaptor calling configure() from
    // didFinishLaunchingWithOptions (the usual Firebase-docs pattern) was
    // tried first, but this struct's own @State default value ran before
    // that delegate callback fired — so the ordering between a property
    // wrapper's default and an adapted UIKit delegate method isn't
    // something to rely on. A custom init sidesteps the question entirely:
    // its statements just run in the order written.
    init() {
        FirebaseApp.configure()
        _authService = State(initialValue: AuthService())
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(authService)
        }
    }
}
