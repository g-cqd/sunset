import AppKit
import WebKit

/// The site's icon for its tab (owner, 2026-11-13): the page's `<link rel="icon">`, else `/favicon.ico`, fetched once the page has
/// loaded, without cookies; kept per host for the app's life. Private pages show their mask and fetch nothing.
extension WebContent {
    /// Icons already fetched, by host (an empty image: the site has none).
    @MainActor private static var known: [String: NSImage] = [:]

    func refreshFavicon() {
        guard settings.favicons, !isPrivate, let webView, let url = webView.url, let host = url.host(),
            ["http", "https"].contains(url.scheme?.lowercased() ?? "")
        else { return }
        if let known = Self.known[host] {
            favicon = known.isValid ? known : nil
            return
        }
        // With what the page says it is: the icon is asked for by Sunset, and must not say otherwise (W-a).
        let script = """
            (() => { const l = document.querySelector('link[rel~="icon"], link[rel="apple-touch-icon"]');
              return [l ? l.href : "", navigator.userAgent] })()
            """
        webView.evaluateJavaScript(script) { [weak self] value, _ in
            let answer = value as? [String] ?? []
            let declared = answer.first.flatMap { $0.isEmpty ? nil : URL(string: $0) }
            let agent = answer.count > 1 ? answer[1] : nil
            MainActor.assumeIsolated {
                self?.fetchFavicon(declared ?? URL(string: "/favicon.ico", relativeTo: url), host: host, agent: agent)
            }
        }
    }

    private func fetchFavicon(_ address: URL?, host: String, agent: String?) {
        // Not asked for at all when the page did not say what it is: better no icon than a request that names Sunset.
        guard let address, let agent, !agent.isEmpty else { return }
        Task { @MainActor [weak self] in
            let session = URLSession(configuration: .ephemeral)
            var request = URLRequest(url: address.absoluteURL)
            request.setValue(agent, forHTTPHeaderField: "User-Agent")
            let data = try? await session.data(for: request).0
            let image = data.flatMap(NSImage.init(data:)) ?? NSImage()
            Self.known[host] = image
            if self?.webView?.url?.host() == host { self?.favicon = image.isValid ? image : nil }
        }
    }
}
