import SwiftUI
import UIKit
import FirebaseCore

// UIKit has no SwiftUI-native way to lock orientation per-screen — the OS
// asks the app's UIApplicationDelegate "which orientations are allowed
// right now," once, whenever it's deciding how to rotate. This tiny class
// is just a mutable box holding whatever the CURRENTLY showing screen
// wants that answer to be. It defaults to .portrait, which is what every
// screen in this app wants except ReadView — see ReadView's own
// .onAppear/.onDisappear, which are the only places this ever changes.
final class OrientationLock {
    static var mask: UIInterfaceOrientationMask = .portrait
}

// The delegate object @UIApplicationDelegateAdaptor below hands to UIKit.
// Its only job is answering this one question — Firebase configuration
// and the one shared AuthService stay in ios_accessibleApp's own custom
// init() below, per that init's own comment on why an AppDelegate
// callback's timing can't be relied on for THOSE. This method is
// different: it only matters later, once the app is already running and
// some screen asks to change orientation, so there's no equivalent
// ordering hazard here.
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        supportedInterfaceOrientationsFor window: UIWindow?
    ) -> UIInterfaceOrientationMask {
        OrientationLock.mask
    }
}

// Called by ReadView to switch to .landscape on appear and back to
// .portrait on disappear. Updates what
// AppDelegate.application(_:supportedInterfaceOrientationsFor:) above
// will answer next, then actively asks the current window scene to
// re-check that answer immediately, rather than waiting for some
// unrelated rotation event to trigger it on its own.
func lockOrientation(to mask: UIInterfaceOrientationMask) {
    OrientationLock.mask = mask

    // This app declares only one scene (no multi-window support), so
    // there's no ambiguity in just taking the first one — filtering by
    // ".activationState == .foregroundActive" (an earlier attempt here)
    // turned out to exclude the scene at exactly the moment ReadView's
    // .onAppear fires, since the scene hasn't necessarily finished
    // transitioning to that exact state yet even though it's already
    // the one and only scene on screen.
    guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
        return
    }

    scene.requestGeometryUpdate(.iOS(interfaceOrientations: mask))
    scene.windows.first?.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()

    // requestGeometryUpdate alone changes what orientations the scene
    // is willing to lay out in, but doesn't reliably trigger the actual
    // full-screen rotation animation on its own. Nudging UIDevice's own
    // "orientation" value via key-value coding is what actually makes
    // the whole screen visibly rotate right away — an old trick (predates
    // requestGeometryUpdate, which only arrived in iOS 16), but still the
    // standard, widely-shipped way apps force a rotation like this one
    // for a reading/video screen, since "orientation" isn't a real
    // public property UIDevice exposes any other way.
    let orientation: UIInterfaceOrientation = (mask == .landscape) ? .landscapeRight : .portrait
    UIDevice.current.setValue(orientation.rawValue, forKey: "orientation")
    // A real, public API (unlike the KVC call above) that tells UIKit to
    // re-ask every view controller what orientations it supports right
    // now and animate to match — without this, the UIDevice value above
    // can end up set but never actually acted on.
    UIViewController.attemptRotationToDeviceOrientation()
}

@main
struct ios_accessibleApp: App {
    // Wires AppDelegate above into the app's actual lifecycle — this is
    // what makes UIKit actually call
    // application(_:supportedInterfaceOrientationsFor:) on it.
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    // Owns the one AuthService for the app's lifetime; handed down to every
    // view via .environment so nothing has to create its own instance. Not
    // read anywhere yet — that's for whenever the login/signup screens get
    // wired up to it.
    @State private var authService: AuthService

    // The reader's saved Light/Dark/Automatic choice (see Theme.swift's
    // AppColorScheme and HomeView's "Appearance" picker, which both read
    // and write this same key). @AppStorage reads and writes UserDefaults
    // directly, so the choice survives being backgrounded or relaunched —
    // stored as AppColorScheme's own rawValue (a String) since that's the
    // simple type @AppStorage knows how to persist; not stored as
    // AppColorScheme itself.
    @AppStorage("appColorScheme") private var appColorSchemeRaw: String = AppColorScheme.system.rawValue

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
                // Applies the app's one accent color (see Theme.swift's
                // Color.accentPrimary) to every native control that reads
                // an accent — Toggle, Slider, ProgressView, etc. — from
                // a single place, rather than tinting each one by hand.
                .tint(Color.accentPrimary)
                // Forces Light or Dark regardless of the system setting
                // when the reader has picked one explicitly; nil (from
                // AppColorScheme.system) leaves this modifier a no-op, so
                // the system's own setting keeps being followed as it
                // always has been.
                .preferredColorScheme((AppColorScheme(rawValue: appColorSchemeRaw) ?? .system).colorScheme)
        }
    }
}
