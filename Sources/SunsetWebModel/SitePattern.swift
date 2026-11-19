package import Foundation

/// What a site's rule is for (the owner's note n40): a host and its subdomains (`example.org`), its subdomains only
/// (`*.example.org`), or the addresses under a prefix (`https://example.org/docs/`). When several match an address the most
/// specific wins: a prefix (the longest), then the host itself, then the nearest site it is under, then a pattern.
package enum SitePattern: Equatable, Sendable {
    case site(String)
    case subdomains(String)
    case prefix(String)

    /// Reads what is typed or kept; nil for what is none of these.
    package init?(_ text: String) {
        let text = text.trimmingCharacters(in: .whitespaces)
        if text.contains("://") {
            guard let url = URL(string: text), url.host() != nil, let scheme = url.scheme?.lowercased(),
                scheme == "http" || scheme == "https"
            else { return nil }
            self = .prefix(text)
            return
        }
        let subdomains = text.hasPrefix("*.")
        let host = SiteHost.key(subdomains ? String(text.dropFirst(2)) : text)
        guard host.contains("."), !host.hasPrefix("."), !host.hasSuffix("."), !host.contains("/"), !host.contains(" ")
        else { return nil }
        self = subdomains ? .subdomains(host) : .site(host)
    }

    /// How it is written and kept.
    package var key: String {
        switch self {
            case .site(let host): host
            case .subdomains(let host): "*." + host
            case .prefix(let address): address
        }
    }

    /// How specific its match of `url` is: nil when it does not match; higher wins. A prefix scores by its length above
    /// every host; a host by its labels (more is nearer), its own host above a site it is under; a pattern below both.
    package func specificity(for url: URL) -> Int? {
        guard let host = url.host().map(SiteHost.key) else { return nil }
        switch self {
            case .prefix(let address):
                return url.absoluteString.hasPrefix(address) ? 1_000_000 + address.count : nil
            case .site(let site):
                if host == site { return 10_000 + 100 * labels(site) }
                return host.hasSuffix("." + site) ? 1_000 + 100 * labels(site) : nil
            case .subdomains(let site):
                return host.hasSuffix("." + site) ? 100 * labels(site) / 10 + 1 : nil
        }
    }

    private func labels(_ host: String) -> Int {
        host.split(separator: ".").count
    }

    /// Whether a host is of this site (itself or under it): for a site; false for the others.
    package func matches(host: String) -> Bool {
        guard case .site(let site) = self else { return false }
        let host = SiteHost.key(host)
        return host == site || host.hasSuffix("." + site)
    }
}
