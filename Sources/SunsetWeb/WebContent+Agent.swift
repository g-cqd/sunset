import Foundation
import WebKit

/// The browser a page's site is shown (roadmap 0022, W-a).
extension WebContent {
    /// The browser the site of `url` is to see: its rule, else the default.
    func agent(for url: URL?) -> BrowserAgent { agents.agent(for: url?.host(), default: settings.agent) }

    /// The browser this page's site sees now.
    package var agent: BrowserAgent { agent(for: url ?? webView?.url) }

    /// Shows the site of `url` its browser, when the view is about to go there. Nil is WebKit's own again.
    func appear(for url: URL?) {
        guard let webView, let scheme = url?.scheme?.lowercased(), ["http", "https"].contains(scheme) else { return }
        let wanted = agent(for: url).userAgent
        if webView.customUserAgent != (wanted ?? "") { webView.customUserAgent = wanted }
    }

    /// Gives this page's site a rule (nil: none, the default), and loads the page again so that the site sees it.
    package func appear(as agent: BrowserAgent?) {
        guard let host = siteHost else { return }
        agents.set(agent, for: host)
        appear(for: url ?? webView?.url)
        webView?.reload()
    }
}
