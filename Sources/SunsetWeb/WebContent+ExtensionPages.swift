import Foundation
import SunsetRuntime
import WebKit

/// An extension's page in a tab (the owner, 2026-11-21: "it seems sunset refuses to open webkit-extension url scheme"):
/// WebKit shows one as a page of its own only in a view made from the extension's configuration, which carries its base URL
/// (else "resource unavailable", -1008). The tab's view is made from it for such a page, and made again when the tab
/// crosses between an extension's pages and the web: a web page never runs in an extension's view, nor the reverse.
extension WebContent {
    /// The extension's configuration when `address` is a page of one of the profile's extensions, else nil.
    func extensionPageConfiguration(for address: URL?) -> WKWebViewConfiguration? {
        guard let address, address.scheme == "webkit-extension", !isPrivate,
            let configuration = ExtensionHosts.shared.host(for: settings.profile)?.pageConfiguration(for: address)
        else { return nil }
        // Its scripts and message handlers are this view's alone: WebKit hands the same content controller out again, and
        // Sunset's handlers added twice end the app (seen 2026-11-21).
        configuration.userContentController = WKUserContentController()
        return configuration
    }

    /// For a view made here: the configuration of the extension whose page the tab shows (its store and controller with it),
    /// its host kept; nil for a web page.
    func configurationForExtensionPage() -> WKWebViewConfiguration? {
        let configuration = extensionPageConfiguration(for: url)
        extensionPageHost = configuration == nil ? nil : url?.host()?.lowercased()
        return configuration
    }

    /// Whether the page is an extension's whose extensions have not loaded yet (at launch, the shown tab is made first): then
    /// the view waits for them, and is made again for the page (`waitForExtensionPage`).
    func waitsForExtensions() -> Bool {
        guard let url, url.scheme == "webkit-extension", extensionPageHost == nil, !isPrivate,
            let host = ExtensionHosts.shared.host(for: settings.profile), !host.isReady
        else { return false }
        runtime.task { @MainActor [weak self, host] in
            await host.ready()
            guard let self, let url = self.url, url.scheme == "webkit-extension", self.extensionPageHost == nil,
                self.webView != nil
            else { return }
            self.remakeView(for: url)
        }
        return true
    }

    /// Whether the view must be made again before `address` loads: it was made for another extension, or for the web.
    func needsOtherView(for address: URL) -> Bool {
        guard webView != nil else { return false }
        let wanted = address.scheme == "webkit-extension" ? address.host()?.lowercased() : nil
        return wanted != extensionPageHost
    }

    /// Makes the view again for `address` (its history not carried over: an extension's view cannot go back to a web page).
    func remakeView(for address: URL) {
        endView(keepingHistory: false)
        url = address
        makeWebView(configuration: nil)
    }
}
