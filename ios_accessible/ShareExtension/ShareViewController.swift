import UIKit
import SwiftUI
import UniformTypeIdentifiers

// Not SLComposeServiceViewController (the Xcode template default) — that's
// built for "compose text, then post it," which isn't this extension's
// job. This grabs the one shared URL, hands it straight to the main app,
// and gets out of the way — deliberately no user-facing choices to make
// here at all.
final class ShareViewController: UIViewController {
    // fileprivate (not private) — ShareStatusView below, a sibling type
    // in this same file rather than a nested/extension member of
    // ShareViewController, needs to reference this too.
    fileprivate enum ShareStatus {
        case working
        case failed
        // extensionContext.open(_:)'s completion handler can genuinely
        // report success: false — confirmed happening on Simulator during
        // this feature's own testing (loadItem succeeded, the callback
        // URL was well-formed, and open() still came back false). Rather
        // than complete the request as if nothing were wrong and leave
        // the reader wondering why Fast Lit never opened, this gives
        // them an honest, actionable message instead of a silent no-op.
        case needsManualOpen
    }

    private var status: ShareStatus = .working {
        didSet { hostingController?.rootView = ShareStatusView(status: status) }
    }
    private var hostingController: UIHostingController<ShareStatusView>?

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

        extractSharedURL()
    }

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

    // fastlit://share?url=<percent-encoded article URL> — the one
    // callback ContentView's .onOpenURL (main app target) listens for.
    // No App Group / shared UserDefaults needed: a single article URL
    // fits comfortably as a query parameter, so the URL itself IS the
    // whole payload — see this session's plan doc for why that's
    // preferred over an App Group here specifically.
    private func openHostApp(with url: URL) {
        var components = URLComponents()
        components.scheme = "fastlit"
        components.host = "share"
        components.queryItems = [URLQueryItem(name: "url", value: url.absoluteString)]

        guard let callbackURL = components.url else {
            fail()
            return
        }

        // completeRequest nested inside open's completion handler (not
        // fired alongside it) — the documented-safe ordering, so the
        // system has actually accepted the open-app request before this
        // extension tears itself down. success==false is a real,
        // reproducible outcome (see needsManualOpen above), not just a
        // theoretical one — shown to the reader instead of dismissed
        // silently.
        extensionContext?.open(callbackURL) { [weak self] success in
            if success {
                self?.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
            } else {
                self?.showNeedsManualOpen()
            }
        }
    }

    private func fail() {
        finish(withStatus: .failed)
    }

    private func showNeedsManualOpen() {
        finish(withStatus: .needsManualOpen)
    }

    // A beat on screen before dismissing, so whichever message is
    // showing is actually visible rather than the sheet just vanishing
    // and looking like nothing happened at all.
    private func finish(withStatus finalStatus: ShareStatus) {
        status = finalStatus
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
            self?.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
        }
    }
}

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
                // Genuinely honest, not "saved, open the app to finish"
                // — there's no App Group/shared storage backing this
                // extension (see this session's plan doc for why), so a
                // failed open() really does lose the URL; asking the
                // reader to share again is the only correct instruction.
                Image(systemName: "exclamationmark.triangle")
                Text("Couldn't open Fast Lit automatically — try sharing again")
            }
        }
        .padding(32)
    }
}
