import WebKit

/// Blocking on this page's site (roadmap 0022 W-c), from the site's panel.
extension WebContent {
    /// Whether ads and trackers are blocked on this page's site now.
    package var blocksOnSite: Bool {
        ContentBlocker.shared.enabled && !ContentBlocker.shared.pauses.isPaused(siteHost)
    }

    /// Pauses blocking on this page's site, or resumes it, and loads the page again so that it takes effect.
    package func setBlocking(_ on: Bool) {
        guard let host = siteHost, let webView else { return }
        ContentBlocker.shared.pauses.set(!on, for: host)
        ContentBlocker.shared.apply(to: webView, host: host)
        webView.reload()
    }
}
