/// A browser Sunset can appear as (roadmap 0022, W-a; the owner, 2026-11-17: Chrome, Edge, Firefox, Safari on macOS). The
/// first rung of R5's ladder only: what the User-Agent says, in the header of every request of the page and to its
/// scripts (`navigator.userAgent`). The engine is still WebKit: no client-hint header is sent (WebKit has none, and gives
/// no way to add a header to every request), and what scripts can probe, and the connection's own fingerprint, are WebKit's.
package enum BrowserAgent: String, Sendable, CaseIterable, Equatable {
    /// Sunset as it is: WebKit's own User-Agent, named as the installed Safari (R1).
    case safari
    case chrome
    case edge
    case firefox

    package var title: String {
        switch self {
            case .safari: "Safari"
            case .chrome: "Chrome"
            case .edge: "Edge"
            case .firefox: "Firefox"
        }
    }

    /// What it says of itself on a Mac; nil for Safari, which is what WebKit says by itself. The version is the major one
    /// the build was given (`AgentVersions`); the rest is what these browsers have frozen: Chrome and Edge say
    /// `10_15_7` and `.0.0.0` whatever the Mac and the release, Firefox `10.15`.
    package var userAgent: String? {
        let chromium = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) "
        switch self {
            case .safari: return nil
            case .chrome: return chromium + "Chrome/\(AgentVersions.chrome).0.0.0 Safari/537.36"
            case .edge:
                return chromium + "Chrome/\(AgentVersions.edge).0.0.0 Safari/537.36 Edg/\(AgentVersions.edge).0.0.0"
            case .firefox:
                let version = AgentVersions.firefox
                return
                    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:\(version).0) Gecko/20100101 Firefox/\(version).0"
        }
    }
}
