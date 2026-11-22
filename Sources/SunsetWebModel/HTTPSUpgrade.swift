/// What a page's navigations ask of WebKit: its settings' `httpsUpgrade`, `hardening`, `globalPrivacyControl`.
package enum HTTPSUpgrade: String, Sendable, Equatable {
    case off, fallback, ask, only
}

extension HTTPSUpgrade {
    /// What a navigation to `host` asks of WebKit.
    package enum Policy: Sendable, Equatable {
        /// As typed or linked: http stays http.
        case keepAsRequested
        /// HTTPS first, http when it fails, without a word.
        case fallBackQuietly
        /// HTTPS first; when it fails, Sunset's failure page, which offers http ("ask") or does not ("only").
        case failVisibly
    }

    /// This machine and the local network are never upgraded (reached over http at once). Under "ask", a host the person
    /// let over http on this page is kept as asked. "ask" is not WebKit's user-mediated fallback: in an app that commits
    /// `about:blank` where Safari shows its own warning (probed 2026-11-20), so a site without HTTPS loaded nothing.
    package func policy(host: String?, allowedOverHTTP: Set<String>) -> Policy {
        if let host, LocalHost.isLocal(host) { return .keepAsRequested }
        switch self {
            case .off: return .keepAsRequested
            case .fallback: return .fallBackQuietly
            case .ask: return host.map { allowedOverHTTP.contains($0) } == true ? .keepAsRequested : .failVisibly
            case .only: return .failVisibly
        }
    }

    /// An address typed without a scheme, failing over HTTPS, is tried over HTTP without a word (one setting for both):
    /// where HTTPS comes first and http follows, or where nothing is upgraded.
    package var retriesTypedOverHTTP: Bool {
        self == .fallback || self == .off
    }

    /// Whether a page that failed at HTTPS is offered http.
    package var offersHTTP: Bool {
        self == .ask
    }
}
