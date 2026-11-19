import WebKit

/// Blocking on this page's site (roadmap 0022 W-c), from the site's panel.
extension WebContent {
    /// Whether ads and trackers are blocked on this page's site now.
    package var blocksOnSite: Bool {
        ContentBlocker.shared.enabled && settings.blocking
            && !ContentBlocker.shared.pauses.isPaused(siteHost, profile: settings.profile)
    }

    /// Pauses blocking on this page's site, or resumes it, and loads the page again so that it takes effect.
    package func setBlocking(_ on: Bool) {
        guard let host = siteHost, let webView else { return }
        // For this page's profile only (roadmap 0050 E); the first profile's are all profiles'.
        ContentBlocker.shared.pauses.set(!on, for: host, profile: settings.profile)
        ContentBlocker.shared.apply(to: webView, host: host)
        webView.reload()
    }

    /// The elements hidden for good on this page's site (W-e).
    package var hiddenOnSite: [String] {
        ContentBlocker.shared.hidden.selectors(for: siteHost)
    }

    /// Lets the person pick an element of the page, and hides it for good on the site.
    package func pickElementToHide() async {
        guard let webView, let host = siteHost, let selector = await ElementPicker.pick(in: webView) else { return }
        ContentBlocker.shared.hidden.add(selector, for: host)
        await ContentBlocker.shared.compileHidden()
    }

    /// Shows the elements hidden on this site again, and loads the page again.
    package func showHiddenElements() async {
        guard let host = siteHost else { return }
        ContentBlocker.shared.hidden.set(nil, for: host)
        await ContentBlocker.shared.compileHidden()
        webView?.reload()
    }
}
