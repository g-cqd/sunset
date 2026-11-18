package import Foundation

/// The Space each site opens in (roadmap 0022 W-d), kept per site (`SiteRules`). A link to such a site, from a page of
/// another Space, opens in its Space, with that Space's profile (its logins).
@MainActor
package enum SiteSpaces {
    package static let shared = make()

    /// Rules kept in memory until a table is given.
    package static func make() -> SiteRules<UUID> {
        SiteRules(encode: \.uuidString, decode: UUID.init(uuidString:))
    }
}

extension SiteRules where Value == UUID {
    /// The Space `host` opens in, its own or its nearest parent site's; never for a bare last label.
    package func space(for host: String?) -> UUID? {
        guard let host, host.contains(".") else { return nil }
        return value(for: host)
    }

    /// The Space a page of `current` going to `url` should open it in instead; nil to go there in place.
    package func elsewhere(_ url: URL, from current: UUID?) -> UUID? {
        guard ["http", "https"].contains(url.scheme?.lowercased() ?? ""), let wanted = space(for: url.host()) else {
            return nil
        }
        return wanted == current ? nil : wanted
    }
}
