import UIKit
import SwiftUI
import UniformTypeIdentifiers

// App Group container this extension shares with the main app target —
// must match ios_accessibleApp's copy of these two constants exactly (see
// ContentView.swift). Confirmed via direct instrumentation that
// extensionContext.open(_:)'s completion handler can report success: false
// within under a millisecond of being called — faster than any real
// cross-process launch round trip, meaning it fails locally before ever
// asking the system to open anything, with no diagnosable cause exposed to
// us. Rather than keep depending on that one unreliable channel, the
// shared URL is written here first — so it survives regardless of what
// open() does — and the main app also checks for it on launch/foreground.
// MARK: - App Group constants

/// App Group container ID; must match ContentView.swift's copy exactly.
private let appGroupID = "group.com.anaydandekar.ios-accessible"
/// UserDefaults key the shared URL is persisted under, read back by the
/// main app on launch/foreground as a fallback if open() fails.
private let pendingSharedURLKey = "pendingSharedArticleURL"

// Not SLComposeServiceViewController (the Xcode template default) — that's
// built for "compose text, then post it," which isn't this extension's
// job. This grabs the one shared URL, hands it straight to the main app,
// and gets out of the way — deliberately no user-facing choices to make
// here at all.
// MARK: - Share extension view controller

/// The Share Extension's entire UI: grabs the shared URL, hands it to the
/// main app (or persists it to the App Group as a fallback), and dismisses.
final class ShareViewController: UIViewController {
    // fileprivate (not private) — ShareStatusView below, a sibling type
    // in this same file rather than a nested/extension member of
    // ShareViewController, needs to reference this too.
    /// The status message shown in the extension's brief on-screen sheet.
    fileprivate enum ShareStatus {
        case working
        case failed
        // extensionContext.open(_:)'s completion handler can genuinely
        // report success: false — confirmed via direct instrumentation
        // (loadItem succeeded, the callback URL was well-formed, and
        // open() still came back false in under a millisecond, before
        // ever reaching the system). The article URL is safe either way
        // (see the App Group write in openHostApp), so this just tells
        // the reader the automatic hand-off didn't happen this time.
        case needsManualOpen
    }

    private var status: ShareStatus = .working {
        didSet { hostingController?.rootView = ShareStatusView(status: status) }
    }
    private var hostingController: UIHostingController<ShareStatusView>?

    // Guards against starting extraction twice — viewDidAppear can fire
    // more than once (e.g. if the system briefly re-presents this view),
    // but extractSharedURL()'s work (loadItem, then open()) should only
    // ever run once per share.
    private var hasStartedExtraction = false

    // MARK: - Lifecycle

    /// Installs the SwiftUI status view as this view controller's only content.
    override func viewDidLoad() {
        super.viewDidLoad()

        let hosting = UIHostingController(rootView: ShareStatusView(status: status))
        addChild(hosting)
        view.addSubview(hosting.view)
        hosting.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hosting.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hosting.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hosting.view.topAnchor.constraint(equalTo: view.topAnchor),
            hosting.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        hosting.didMove(toParent: self)
        hostingController = hosting
    }

    // extractSharedURL() (and, downstream of it, extensionContext.open())
    // starts here instead of viewDidLoad — viewDidLoad fires before this
    // view is actually on screen, and loadItem for a URL is fast enough
    // that open() was reaching Apple's private implementation before the
    // extension's own scene had finished becoming active. That lines up
    // with what direct instrumentation showed: open()'s completion firing
    // in under a millisecond, well before any real cross-process launch
    // could round-trip — consistent with a readiness check failing
    // locally, not a genuine system-level rejection. viewDidAppear is the
    // earliest point UIKit confirms this view is actually presented.
    /// Starts extraction once the view is actually on screen (see the
    /// comment above on why this waits for viewDidAppear, not viewDidLoad).
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !hasStartedExtraction else { return }
        hasStartedExtraction = true
        extractSharedURL()
    }

    // MARK: - Extraction and hand-off

    /// Pulls the shared URL out of the extension's input items, then hands
    /// it to openHostApp — or fails if none is found.
    private func extractSharedURL() {
        guard
            let item = extensionContext?.inputItems.first as? NSExtensionItem,
            let provider = item.attachments?.first(where: {
                $0.hasItemConformingToTypeIdentifier(UTType.url.identifier)
            })
        else {
            fail()
            return
        }

        provider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { [weak self] value, error in
            guard let self, error == nil, let sharedURL = value as? URL else {
                DispatchQueue.main.async { self?.fail() }
                return
            }
            DispatchQueue.main.async { self.openHostApp(with: sharedURL) }
        }
    }

    // fastlit://share?url=<percent-encoded article URL> — the callback
    // ContentView's .onOpenURL (main app target) listens for when open()
    // actually works, letting the article open instantly without the
    // reader having to switch apps themselves.
    /// Persists the shared URL to the App Group, then attempts to open the
    /// main app directly via its `fastlit://` URL scheme.
    private func openHostApp(with url: URL) {
        // Written before even attempting open() — the one part of this
        // method guaranteed to matter regardless of what open() does.
        UserDefaults(suiteName: appGroupID)?.set(url.absoluteString, forKey: pendingSharedURLKey)

        var components = URLComponents()
        components.scheme = "fastlit"
        components.host = "share"
        components.queryItems = [URLQueryItem(name: "url", value: url.absoluteString)]

        guard let callbackURL = components.url else {
            // The App Group write above already succeeded (url itself,
            // not the constructed callbackURL, is what's stored) — so
            // even though the instant hand-off can't happen, the article
            // isn't lost, matching the .needsManualOpen messaging below.
            showNeedsManualOpen()
            return
        }

        attemptOpen(callbackURL, remainingRetries: 2)
    }

    // open()'s failure was clocked at under a millisecond — far faster
    // than a real cross-process launch — which points to a local
    // readiness race rather than a hard rejection (see viewDidAppear's
    // own comment). A couple of short-delayed retries are cheap and give
    // that race a chance to resolve before falling back to the App
    // Group-only path; completeRequest still only ever fires once, from
    // whichever branch — success, out of retries, or malformed URL —
    // actually finishes first.
    /// Tries extensionContext.open(), retrying a couple of times on
    /// failure before falling back to the App Group-only path.
    private func attemptOpen(_ callbackURL: URL, remainingRetries: Int) {
        // completeRequest nested inside open's completion handler (not
        // fired alongside it) — the documented-safe ordering, so the
        // system has actually accepted the open-app request before this
        // extension tears itself down. success==false is a real,
        // reproducible outcome (see needsManualOpen above), not just a
        // theoretical one — shown to the reader instead of dismissed
        // silently.
        extensionContext?.open(callbackURL) { [weak self] success in
            guard let self else { return }
            if success {
                self.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
            } else if remainingRetries > 0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    self.attemptOpen(callbackURL, remainingRetries: remainingRetries - 1)
                }
            } else {
                self.showNeedsManualOpen()
            }
        }
    }

    // MARK: - Terminal states

    /// No usable URL was found in the share sheet's input.
    private func fail() {
        finish(withStatus: .failed)
    }

    /// The URL is safely persisted, but the automatic app hand-off didn't happen.
    private func showNeedsManualOpen() {
        finish(withStatus: .needsManualOpen)
    }

    // A beat on screen before dismissing, so whichever message is
    // showing is actually visible rather than the sheet just vanishing
    // and looking like nothing happened at all.
    /// Shows `finalStatus` briefly, then completes the extension request.
    private func finish(withStatus finalStatus: ShareStatus) {
        status = finalStatus
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
            self?.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
        }
    }
}

// MARK: - Status view

/// The extension's brief on-screen sheet, one message per ShareStatus case.
private struct ShareStatusView: View {
    let status: ShareViewController.ShareStatus

    var body: some View {
        VStack(spacing: 16) {
            switch status {
            case .working:
                ProgressView()
                Text("Saving to Fast Lit…")
            case .failed:
                Image(systemName: "exclamationmark.triangle")
                Text("Couldn't read this link")
            case .needsManualOpen:
                Image(systemName: "checkmark.circle")
                Text("Saved — open Fast Lit to finish")
            }
        }
        .padding(32)
    }
}
