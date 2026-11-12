import AppKit
import WebKit

/// What WebKit asks of a page (`WKNavigationDelegate`, `WKUIDelegate`): new pages go to their place, a failure is shown as ours, an accepted certificate is
/// let through, a page that closes itself closes its pane.
@MainActor final class WebCoordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
    weak var content: WebContent?

    init(content: WebContent) { self.content = content }

    /// Cmd-click on a link opens it in a tab right after, not shown (as a link asking for a new tab does).
    func webView(_ webView: WKWebView, decidePolicyFor action: WKNavigationAction) async -> WKNavigationActionPolicy {
        guard action.navigationType == .linkActivated, action.modifierFlags.contains(.command),
            let url = action.request.url,
            let content
        else { return .allow }
        content.onOpen(WebContent(url: url, settings: content.settings), .tabAfter)
        return .cancel
    }

    func webView(
        _ webView: WKWebView,
        didFailProvisionalNavigation navigation: WKNavigation?,
        withError error: any Error
    ) {
        content?.failure = WebFailure(error, url: content?.url)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation?, withError error: any Error) {
        content?.failure = WebFailure(error, url: webView.url)
    }

    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation?) { content?.failure = nil }

    func webView(_ webView: WKWebView, respondTo challenge: URLAuthenticationChallenge) async
        -> (URLSession.AuthChallengeDisposition, URLCredential?)
    {
        let space = challenge.protectionSpace
        guard space.authenticationMethod == NSURLAuthenticationMethodServerTrust, let trust = space.serverTrust,
            content?.acceptedHosts.contains(space.host) == true
        else { return (.performDefaultHandling, nil) }
        return (.useCredential, URLCredential(trust: trust))
    }

    /// A page asks for a new one (a link with a target, the link menu, `window.open` after a click): made at once with WebKit's configuration, then
    /// placed. A sized window asked by the page gets a window (R1: "a sized popup is a small window").
    func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for action: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        guard let content else { return nil }
        let placement =
            (webView as? SunsetWebView)?.pendingPlacement ?? (windowFeatures.width != nil ? .window : .tabAfter)
        (webView as? SunsetWebView)?.pendingPlacement = nil
        let opened = WebContent(configuration: configuration, settings: content.settings)
        content.onOpen(opened, placement)
        return opened.webView
    }

    func webViewDidClose(_ webView: WKWebView) { content?.onExit() }
}
