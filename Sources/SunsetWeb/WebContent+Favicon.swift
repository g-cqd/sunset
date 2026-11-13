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
        let script = """
            (() => { const l = document.querySelector('link[rel~="icon"], link[rel="apple-touch-icon"]');
              return l ? l.href : null })()
            """
        webView.evaluateJavaScript(script) { [weak self] value, _ in
            let declared = (value as? String).flatMap(URL.init(string:))
            MainActor.assumeIsolated {
                self?.fetchFavicon(declared ?? URL(string: "/favicon.ico", relativeTo: url), host: host)
            }
        }
    }

    private func fetchFavicon(_ address: URL?, host: String) {
        guard let address else { return }
        Task { @MainActor [weak self] in
            let session = URLSession(configuration: .ephemeral)
            let data = try? await session.data(from: address.absoluteURL).0
            let image = data.flatMap(NSImage.init(data:)) ?? NSImage()
            Self.known[host] = image
            if self?.webView?.url?.host() == host { self?.favicon = image.isValid ? image : nil }
        }
    }
}
