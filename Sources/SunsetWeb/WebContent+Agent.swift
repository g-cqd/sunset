import Foundation
import WebKit

/// The browser a page's site is shown (roadmap 0022, W-a).
extension WebContent {
    /// The browser the site of `url` is to see: its rule, else the default.
    func agent(for url: URL?) -> BrowserAgent {
        guard let url else { return settings.agent }
        // An extension store is shown the browser it serves, whatever the default or a rule: only then does it offer its
        // install, which Sunset takes (roadmap 0109 E; the owner, 2026-11-21: it "should always be possible").
        if let store = ExtensionStoreLink.storeAgent(forHost: url.host()) { return store }
        return agents.agent(for: url, default: settings.agent, profile: settings.profile)
    }

    /// The browser this page's site sees now.
    package var agent: BrowserAgent {
        agent(for: url ?? webView?.url)
    }

    /// Shows the site of `url` its browser, when the view is about to go there. Nil is WebKit's own again.
    func appear(for url: URL?) {
        guard let webView, let scheme = url?.scheme?.lowercased(), ["http", "https"].contains(scheme) else { return }
        let wanted = agent(for: url).userAgent
        if webView.customUserAgent != (wanted ?? "") { webView.customUserAgent = wanted }
    }

    /// Gives this page's site a rule (nil: none, the default), and loads the page again so that the site sees it: at the
    /// address the person asked for when a script of the site has sent the page away from it since (a site's "browser
    /// not supported" page never sends a browser back; roadmap 0045 F), else where it is.
    package func appear(as agent: BrowserAgent?) {
        guard let host = siteHost else { return }
        agents.set(agent, for: host, profile: settings.profile)
        if let target = asked.target(current: webView?.url ?? url) {
            load(target)
            return
        }
        appear(for: url ?? webView?.url)
        webView?.reload()
    }
}
