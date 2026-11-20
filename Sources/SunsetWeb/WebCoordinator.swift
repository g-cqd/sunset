import AppKit
import WebKit

/// What WebKit asks of a page (`WKNavigationDelegate`, `WKUIDelegate`): new pages go to their place, a failure is shown as ours, an accepted certificate is
/// let through, a page that closes itself closes its pane.
@MainActor final class WebCoordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
    weak var content: WebContent?

    init(content: WebContent) {
        self.content = content
        super.init()
        Self.installPrivateQuestions()
        Self.installMenuDownloads()
    }

    /// Each navigation's HTTPS policy by its host (this machine and the local network never upgraded; a host let over http
    /// kept), then what is done with it.
    func webView(
        _ webView: WKWebView,
        decidePolicyFor action: WKNavigationAction,
        preferences: WKWebpagePreferences
    ) async -> (WKNavigationActionPolicy, WKWebpagePreferences) {
        if action.targetFrame?.isMainFrame == true, let content {
            let wanted = WebProtection.preferences(
                for: content.settings,
                host: action.request.url?.host(),
                allowedOverHTTP: content.httpHosts
            )
            preferences.preferredHTTPSNavigationPolicy = wanted.preferredHTTPSNavigationPolicy
        }
        return (await decide(action, in: webView), preferences)
    }

    /// Cmd-click on a link opens it in a tab right after, not shown (as a link asking for a new tab does).
    private func decide(_ action: WKNavigationAction, in webView: WKWebView) async -> WKNavigationActionPolicy {
        // The page the view goes to is shown the browser its site is to see (W-a): set before the request leaves.
        if action.targetFrame?.isMainFrame == true {
            content?.asked.navigation(to: action.request.url, type: action.navigationType)
            content?.appear(for: action.request.url)
            // Blocking, or its pause on the site the page goes to (W-c): decided before the page loads.
            ContentBlocker.shared.apply(to: webView, host: action.request.url?.host())
        }
        // A link to a site that opens in another Space goes there, with that Space's profile (W-d).
        if action.targetFrame?.isMainFrame == true, action.navigationType == .linkActivated, let content,
            !content.isPrivate, let url = action.request.url,
            let space = SiteSpaces.shared.elsewhere(
                url,
                from: content.currentSpace(),
                profile: content.settings.profile
            )
        {
            content.openInSpace(url, space)
            return .cancel
        }
        // A link that says download, or an Option-click (web step f).
        if action.shouldPerformDownload
            || (action.navigationType == .linkActivated && action.modifierFlags.contains(.option))
        {
            return .download
        }
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
        guard let failure = WebFailure(error, url: content?.url) else { return }
        if content?.fallBackToHTTP(after: failure) != true { content?.failure = failure }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation?, withError error: any Error) {
        content?.failure = WebFailure(error, url: webView.url)
    }

    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation?) {
        content?.failure = nil
        content?.fallbackHost = nil
        content?.dialogPolicy.pageLeft()
        content?.linkHovered(nil)
        if let url = webView.url, ["http", "https"].contains(url.scheme?.lowercased() ?? "") {
            // A restored page has its title before WebKit gives it again: that one is kept with the visit.
            let title = (webView.title ?? "").isEmpty ? (content?.pageTitle ?? "") : (webView.title ?? "")
            content?.history?.visit(url.absoluteString, title: title)
        }
    }

    func webView(_ webView: WKWebView, respondTo challenge: URLAuthenticationChallenge) async
        -> (URLSession.AuthChallengeDisposition, URLCredential?)
    {
        let space = challenge.protectionSpace
        // A server's own question (roadmap 0029 step 8): asked in the page; kept for this run of Sunset only.
        if [NSURLAuthenticationMethodHTTPBasic, NSURLAuthenticationMethodHTTPDigest]
            .contains(space.authenticationMethod)
        {
            let answer = await content?
                .askCredential(
                    host: space.host,
                    realm: space.realm ?? "",
                    failed: challenge.previousFailureCount > 0,
                    secure: space.receivesCredentialSecurely
                )
            guard let answer else { return (.cancelAuthenticationChallenge, nil) }
            return (
                .useCredential, URLCredential(user: answer.user, password: answer.password, persistence: .forSession)
            )
        }
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
        let chosen = (webView as? SunsetWebView)?.pendingPlacement
        guard let content, Self.skipsPopupRule(chosen: chosen) || popupAllowed(action, from: webView) else {
            return nil
        }
        let placement = Self.placement(
            chosen: chosen,
            sized: windowFeatures.width != nil || windowFeatures.height != nil,
            fromLink: action.navigationType == .linkActivated,
            popups: content.settings.popupWindows
        )
        (webView as? SunsetWebView)?.pendingPlacement = nil
        if placement == .privateTab {
            // Not WebKit's page: its configuration would tie it to this page's store.
            var settings = content.settings
            settings.privacy = PagePrivacy()
            if let url = action.request.url { content.onOpen(WebContent(url: url, settings: settings), .tabAfter) }
            return nil
        }
        let opened = WebContent(configuration: configuration, settings: content.settings)
        if placement == .popup {
            opened.popupSize = windowFeatures.width.map { width in
                CGSize(width: width.doubleValue, height: windowFeatures.height?.doubleValue ?? width.doubleValue * 0.75)
            }
        }
        content.onOpen(opened, placement)
        return opened.webView
    }

    /// A page asked for by one of the menu's items the person chose (Sunset's link items, WebKit's Open Image or Video) is
    /// theirs: WebKit marks it as not opened by the person, and the pop-up rule would stop it (note n64).
    nonisolated static func skipsPopupRule(chosen: WebPlacement?) -> Bool {
        chosen != nil
    }

    /// Where a page WebKit asks for goes: where Sunset's own menu item said; else a pop-up window, as `web.popupWindows` says
    /// (never for a link with a target); else an opened page (a tab after its opener).
    nonisolated static func placement(
        chosen: WebPlacement?,
        sized: Bool,
        fromLink: Bool,
        popups: PopupWindows
    ) -> WebPlacement {
        chosen ?? (popups.takes(sized: sized, fromLink: fromLink) ? .popup : .opened)
    }

    func webViewDidClose(_ webView: WKWebView) {
        content?.onExit()
    }
}
