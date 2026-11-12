import WebKit

extension WebContent {
    /// The address as a field shows it when not typed in: the host, without "www." (Safari's way).
    package var shownHost: String {
        guard let host = url?.host() else { return url?.absoluteString ?? "" }
        return host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
    }

    package func goBack() {
        failure = nil
        webView?.goBack()
    }

    package func goForward() {
        failure = nil
        webView?.goForward()
    }

    package func stopLoading() { webView?.stopLoading() }

    /// The page is over plain http to a host that is not this machine or the local network: the field says Not Secure.
    package var isNotSecure: Bool {
        guard let url, url.scheme?.lowercased() == "http", let host = url.host() else { return false }
        return !LocalHost.isLocal(host)
    }

    /// https failed for a host typed without a scheme while the http setting is on: the same address over http, once. True when it was tried.
    func fallBackToHTTP(after failure: WebFailure) -> Bool {
        guard let host = fallbackHost, let failed = failure.url, failed.host() == host, failed.scheme == "https",
            var parts = URLComponents(url: failed, resolvingAgainstBaseURL: false)
        else { return false }
        fallbackHost = nil
        parts.scheme = "http"
        guard let plain = parts.url else { return false }
        load(plain)
        return true
    }

    /// The page takes the keyboard (after an address was typed, or typing was given up).
    package func focusPage() {
        guard let webView else { return }
        webView.window?.makeFirstResponder(webView)
    }
}
