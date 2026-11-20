import Foundation
import WebKit

/// A page as WebKit's extensions see a tab (probed: without one, `runtime.sendMessage` from a content script finds no tab).
@MainActor final class ExtensionTab: NSObject, WKWebExtensionTab {
    weak var page: WebContent?

    init(_ page: WebContent) {
        self.page = page
    }

    func webView(for context: WKWebExtensionContext) -> WKWebView? {
        page?.webView
    }

    func title(for context: WKWebExtensionContext) -> String? {
        page?.pageTitle
    }

    func url(for context: WKWebExtensionContext) -> URL? {
        page?.url
    }
}
