package import Foundation
package import WebKit

/// A page as WebKit's extensions see a tab (probed: without one, `runtime.sendMessage` from a content script finds no tab).
@MainActor package final class ExtensionTab: NSObject, WKWebExtensionTab {
    weak var page: WebContent?

    init(_ page: WebContent) {
        self.page = page
    }

    package func webView(for context: WKWebExtensionContext) -> WKWebView? {
        page?.webView
    }

    package func title(for context: WKWebExtensionContext) -> String? {
        page?.pageTitle
    }

    package func url(for context: WKWebExtensionContext) -> URL? {
        page?.url
    }

    /// The window it is a tab of.
    package func window(for context: WKWebExtensionContext) -> (any WKWebExtensionWindow)? {
        guard let page else { return nil }
        return ExtensionHosts.shared.window(of: page)
    }

    package func isSelected(for context: WKWebExtensionContext) -> Bool {
        guard let page else { return false }
        return ExtensionHosts.shared.windows().contains { $0.shown() === page }
    }

    package func activate(for context: WKWebExtensionContext) async throws {
        page?.onFocusRequest()
    }

    package func close(for context: WKWebExtensionContext) async throws {
        page?.onExit()
    }
}
