import SwiftUI
import FirebaseCore

// The App protocol has no launch hook of its own, so this bridges in the
// old UIKit AppDelegate lifecycle just to get one — FirebaseApp.configure()
// has to run once, before anything touches Firebase, and this is where the
// Firebase docs say to put it.
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                      didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        FirebaseApp.configure()

        return true
    }
}

@main
struct ios_accessibleApp: App {
    // Registers AppDelegate above so its didFinishLaunchingWithOptions
    // actually runs as part of this SwiftUI app's launch.
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
