import AppKit
import SunsetRuntime
import WebKit

/// The site's icon for its tab: the page's `<link rel="icon">`, else `/favicon.ico`, fetched once the page has loaded, without
/// cookies. Kept on disk by host (`FaviconStore`) until the server says it expires, so that a tab not loaded shows it too; an icon
/// the page changes while it runs (`IconWatch`) replaces the one kept. Private pages show their mask, and fetch and keep nothing.
extension WebContent {
    /// The most read of a site's icon.
    static let faviconLimit = 1 << 20

    /// Hosts that have no icon, this run: not asked again until the next.
    @MainActor private static var missing: Set<String> = []
    // (by profile and host, as kept)

    func refreshFavicon() {
        guard settings.favicons, !isPrivate, let webView, let url = webView.url, let host = url.host(),
            ["http", "https"].contains(url.scheme?.lowercased() ?? "")
        else { return }
        // What is kept shows at once, fresh or not.
        favicon = icons.image(for: host, profile: settings.profile)
        if favicon == nil, Self.missing.contains(FaviconStore.key(host: host, profile: settings.profile)) { return }
        // With what the page says it is: the icon is asked for by Sunset, and must not say otherwise.
        let script = """
            (() => { const l = document.querySelector('link[rel~="icon"], link[rel="apple-touch-icon"]');
              return [l ? l.href : "", navigator.userAgent] })()
            """
        webView.evaluateJavaScript(script) { [weak self] value, _ in
            let answer = value as? [String] ?? []
            // What the page names, from the web only (white paper §9): never a file of the Mac.
            let declared = answer.first.flatMap { $0.isEmpty ? nil : URL(string: $0) }
                .flatMap {
                    WebFetch.allows($0) ? $0 : nil
                }
            let agent = answer.count > 1 ? answer[1] : nil
            MainActor.assumeIsolated {
                guard let self else { return }
                let address = declared ?? URL(string: "/favicon.ico", relativeTo: url)
                if self.icons.isFresh(host: host, profile: self.settings.profile, source: declared) { return }
                self.fetchFavicon(address, host: host, agent: agent)
            }
        }
    }

    /// The page changed its icon while it runs: the new one is fetched and replaces the one kept.
    func iconChanged(to address: String) {
        guard settings.favicons, !isPrivate, let webView, let host = webView.url?.host(),
            let url = URL(string: address, relativeTo: webView.url),
            ["http", "https", "data"].contains(url.scheme?.lowercased() ?? "")
        else { return }
        let now = ProcessInfo.processInfo.systemUptime
        // At most one a second: a page that animates its icon is not followed frame by frame.
        if let last = lastIconChange, now >= last, now - last < 1 { return }
        lastIconChange = now
        webView.evaluateJavaScript("navigator.userAgent") { [weak self] agent, _ in
            MainActor.assumeIsolated { self?.fetchFavicon(url, host: host, agent: agent as? String) }
        }
    }

    private func fetchFavicon(_ address: URL?, host: String, agent: String?) {
        // Not asked for at all when the page did not say what it is: better no icon than a request that names Sunset.
        guard let address, let agent, !agent.isEmpty else { return }
        runtime.task { @MainActor [weak self, runtime] in
            let fetched = await WebFetch.data(address, agent: agent, limit: Self.faviconLimit)
            guard let self else { return }
            let expires = FaviconStore.expiry(of: fetched?.response as? HTTPURLResponse, at: runtime.now())
            if let data = fetched?.data,
                icons.keep(
                    host: host,
                    profile: settings.profile,
                    source: address.absoluteURL,
                    data: data,
                    expires: expires
                )
            {
                Self.missing.remove(FaviconStore.key(host: host, profile: settings.profile))
            } else if icons.image(for: host, profile: settings.profile) == nil {
                Self.missing.insert(FaviconStore.key(host: host, profile: settings.profile))
            }
            if webView?.url?.host() == host { favicon = icons.image(for: host, profile: settings.profile) }
        }
    }
}
