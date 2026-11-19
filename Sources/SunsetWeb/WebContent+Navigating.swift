package import Foundation
import SunsetRuntime
import WebKit

/// Where a page goes: what was typed, an address, back and forward, again.
extension WebContent {
    // MARK: Navigating

    /// Opens what was typed: an address, or a search with the engine it names or the chosen one.
    package func open(typed: String) {
        guard let input = settings.input(typed) else { return }
        open(input)
    }

    package func open(_ input: WebInput) {
        guard let address = input.url else { return }
        if case .address(_, let guessed) = input, guessed, settings.httpFallback { fallbackHost = address.host() }
        load(address)
    }

    package func load(_ address: URL) {
        url = address
        asked.asked(address)
        failure = nil
        if webView == nil { makeWebView(configuration: nil) }
        webView?.load(URLRequest(url: address))
        onChange()
    }

    /// Loads the page again; `fromOrigin`: without what the cache holds (Shift-Cmd-R).
    package func reload(fromOrigin: Bool = false) {
        failure = nil
        if let url, webView?.url == nil {
            webView?.load(URLRequest(url: url))
        } else if fromOrigin {
            webView?.reloadFromOrigin()
        } else {
            webView?.reload()
        }
    }

    /// Visit Anyway: the certificate of this host is accepted for this page, and the page is loaded again.
    package func acceptCertificate() {
        guard let host = failure?.url?.host() else { return }
        acceptedHosts.insert(host)
        if let address = failure?.url { load(address) }
    }
}
