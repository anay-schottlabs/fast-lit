import Foundation
import WebKit
import UIKit

// MARK: - Errors

// Thrown by ArticleExtractionService.extract(from:) — each case has its own
// user-facing message, since "share a link" can fail in several genuinely
// different ways a reader would want to distinguish (a dead link reads
// differently than "this isn't an article").
/// The ways loading and extracting a shared article can fail, each with
/// its own user-facing message.
enum ArticleExtractionError: LocalizedError {
    case invalidURL
    case loadFailed(Error)
    case timedOut
    case noContentFound

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "That link doesn't look valid."
        case .loadFailed:
            return "Couldn't load that page. Check your connection and try again."
        case .timedOut:
            return "That page took too long to load."
        case .noContentFound:
            return "Couldn't find an article on that page — it may be behind a paywall, or not be an article."
        }
    }
}

// Turns a shared web URL into a ReadableContent by loading the page in a
// hidden WKWebView and running Mozilla's Readability.js (the same
// extraction library behind Firefox's Reader View — see Readability.js in
// this same folder, vendored from github.com/mozilla/readability, Apache
// 2.0) against its DOM. This deliberately lives in the main app, not the
// Share Extension: extensions have tight memory/CPU time limits, and a
// WKWebView load + JS run is exactly the kind of unpredictable-duration
// work that risks the extension's own OS-imposed timeout — the extension's
// only job is a fast local handoff (see ShareExtension/ShareViewController.swift).
// MARK: - Extraction

/// Loads a shared URL in a hidden WKWebView and runs Readability.js
/// against it to produce a plain-text ReadableContent.
@MainActor
final class ArticleExtractionService: NSObject, WKNavigationDelegate {
    private var loadContinuation: CheckedContinuation<Void, Error>?

    /// Extracts a ReadableContent from a shared URL. Throws
    /// ArticleExtractionError on any failure along the way.
    static func extract(from url: URL) async throws -> ReadableContent {
        try await ArticleExtractionService().run(url: url)
    }

    private func run(url: URL) async throws -> ReadableContent {
        let webView = WKWebView(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
        webView.navigationDelegate = self

        // A WKWebView needs to actually be part of a window's view
        // hierarchy for some pages' JS/layout to behave the same way it
        // would visibly on screen (lazy-loaded content, IntersectionObserver-
        // gated rendering, etc.) — kept effectively invisible via alpha
        // rather than .isHidden, since a genuinely hidden WKWebView is
        // documented to sometimes suspend its own JS execution.
        guard
            let window = UIApplication.shared.connectedScenes
                .compactMap({ ($0 as? UIWindowScene)?.windows.first })
                .first
        else {
            throw ArticleExtractionError.loadFailed(
                NSError(domain: "ArticleExtractionService", code: -1)
            )
        }
        webView.alpha = 0.01
        webView.isUserInteractionEnabled = false
        window.insertSubview(webView, at: 0)
        defer { webView.removeFromSuperview() }

        try await withTimeout(seconds: 15) {
            try await withCheckedThrowingContinuation { continuation in
                self.loadContinuation = continuation
                webView.load(URLRequest(url: url))
            }
        }

        guard
            let readabilityURL = Bundle.main.url(forResource: "Readability", withExtension: "js"),
            let readabilitySource = try? String(contentsOf: readabilityURL, encoding: .utf8)
        else {
            throw ArticleExtractionError.noContentFound
        }

        // Returns a JSON STRING (via JSON.stringify), not a bridged JS
        // object — a single string round-trip is a faster, less finicky
        // bridge for a long article's textContent than WKWebView's
        // object-graph bridging, which is pickier about non-JSON-safe
        // values.
        //
        // Deliberately NOT article.textContent directly: that's the DOM's
        // native Node.textContent, which concatenates every text node
        // with zero separator between them — a paragraph ending "...end
        // of sentence." immediately followed by a new paragraph starting
        // "Next line..." comes back as one glued-together
        // "sentence.Next" with nothing between them, which then reads as
        // a single (wrong) RSVP word. Walking article.content's own DOM
        // ourselves and inserting a paragraph break at each block-level
        // element's start fixes that at the source, before ReadView ever
        // sees the text, rather than trying to guess it back out later.
        let script = readabilitySource + """
        (function () {
            try {
                var article = new Readability(document.cloneNode(true)).parse();
                if (!article || !article.textContent) { return null; }

                var textContent = article.textContent;
                if (article.content) {
                    var container = document.createElement("div");
                    container.innerHTML = article.content;
                    var blockTags = {
                        P: 1, DIV: 1, LI: 1, BLOCKQUOTE: 1, PRE: 1, TR: 1,
                        H1: 1, H2: 1, H3: 1, H4: 1, H5: 1, H6: 1, BR: 1
                    };
                    var parts = [];
                    (function walk(node) {
                        if (node.nodeType === 3) {
                            parts.push(node.textContent);
                            return;
                        }
                        if (node.nodeType !== 1) { return; }
                        if (blockTags[node.tagName] && parts.length > 0) {
                            parts.push("\\n\\n");
                        }
                        for (var i = 0; i < node.childNodes.length; i++) {
                            walk(node.childNodes[i]);
                        }
                    })(container);
                    var walked = parts.join("")
                        .replace(/\\n{3,}/g, "\\n\\n")
                        .replace(/[ \\t]+\\n/g, "\\n")
                        .trim();
                    if (walked) { textContent = walked; }
                }

                return JSON.stringify({
                    title: article.title || "",
                    textContent: textContent,
                    excerpt: article.excerpt || ""
                });
            } catch (e) {
                return null;
            }
        })();
        """

        let result = try await webView.evaluateJavaScript(script)
        guard
            let jsonString = result as? String,
            let data = jsonString.data(using: .utf8),
            let parsed = try? JSONDecoder().decode(ReadabilityResult.self, from: data),
            !parsed.textContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            throw ArticleExtractionError.noContentFound
        }

        return ReadableContent(
            id: UUID().uuidString,
            title: parsed.title.isEmpty ? (url.host ?? "Shared Article") : parsed.title,
            description: parsed.excerpt,
            text: parsed.textContent,
            source: .saved,
            sourceURL: url.absoluteString
        )
    }

    // MARK: - WKNavigationDelegate

    /// Resolves loadContinuation once the page finishes loading.
    nonisolated func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        Task { @MainActor in
            loadContinuation?.resume(returning: ())
            loadContinuation = nil
        }
    }

    /// Fails loadContinuation if the page errors after navigation commits.
    nonisolated func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        Task { @MainActor in
            loadContinuation?.resume(throwing: ArticleExtractionError.loadFailed(error))
            loadContinuation = nil
        }
    }

    /// Fails loadContinuation if the page errors before navigation commits.
    nonisolated func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        Task { @MainActor in
            loadContinuation?.resume(throwing: ArticleExtractionError.loadFailed(error))
            loadContinuation = nil
        }
    }
}

/// Decodes the JSON string produced by the extraction JS's JSON.stringify.
private struct ReadabilityResult: Decodable {
    let title: String
    let textContent: String
    let excerpt: String
}

// Readability's own parse() can occasionally hang on a pathological page
// (an infinite-scroll SPA that never fires a clean "finished loading")
// without ever erroring — this bounds every extraction attempt so the
// caller's spinner (see ContentView's isExtractingSharedArticle) always
// resolves one way or another instead of spinning forever.
// MARK: - Timeout helper

/// Races `operation` against a `seconds`-long timer, throwing
/// ArticleExtractionError.timedOut if the timer wins.
private func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
    try await withThrowingTaskGroup(of: T.self) { group in
        group.addTask { try await operation() }
        group.addTask {
            try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            throw ArticleExtractionError.timedOut
        }
        let result = try await group.next()!
        group.cancelAll()
        return result
    }
}
