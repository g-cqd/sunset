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
        if case .address(_, let guessed) = input, guessed, settings.httpsUpgrade.retriesTypedOverHTTP {
            fallbackHost = address.host()
        }
        load(address)
    }

    package func load(_ address: URL) {
        url = address
        asked.asked(address)
        failure = nil
        if needsOtherView(for: address) {
            remakeView(for: address)
        } else if webView == nil {
            makeWebView(configuration: nil)
        }
        webView?.load(URLRequest(url: address))
        onChange()
    }

    /// Loads the page again; `fromOrigin`: without what the cache holds (Shift-Cmd-R).
    package func reload(fromOrigin: Bool = false) {
        failure = nil
        if let url, needsOtherView(for: url) {
            // A page shown in a view of the wrong kind (an extension's page in a web view): made again, not reloaded there.
            load(url)
        } else if let url, webView?.url == nil {
            webView?.load(URLRequest(url: url))
        } else if fromOrigin {
            webView?.reloadFromOrigin()
        } else {
            webView?.reload()
        }
    }

    /// A page that failed at HTTPS, under "ask", is offered http: the address that failed is an https one of a host not let
    /// through yet. (Under "ask" a typed or linked http address is upgraded first, so the failure's address is https.)
    package func offersHTTP(after failure: WebFailure) -> Bool {
        guard settings.httpsUpgrade.offersHTTP, !failure.isCertificate, let failed = failure.url,
            failed.scheme == "https", let host = failed.host()
        else { return false }
        return !httpHosts.contains(host)
    }

    /// Load over HTTP: HTTPS failed for this host ("ask"); it is kept as asked on this page, and the address loaded over http.
    package func loadOverHTTP() {
        guard let failed = failure?.url, let host = failed.host(),
            var parts = URLComponents(url: failed, resolvingAgainstBaseURL: false)
        else { return }
        httpHosts.insert(host)
        parts.scheme = "http"
        if let plain = parts.url { load(plain) }
    }

    /// Visit Anyway: the certificate the person was shown, for this host, is accepted on this page (no other one), and
    /// the page is loaded again — unless MDM managed policy forbids certificate exceptions (`allowsCertificateExceptions`).
    package func acceptCertificate() {
        guard settings.allowsCertificateExceptions,
            let host = failure?.url?.host(),
            let certificate = failure?.certificate
        else { return }
        acceptedCertificates.accept(host: host, certificate: certificate)
        if let address = failure?.url { load(address) }
    }
}
