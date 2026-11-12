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

    /// The page takes the keyboard (after an address was typed, or typing was given up).
    package func focusPage() {
        guard let webView else { return }
        webView.window?.makeFirstResponder(webView)
    }
}
