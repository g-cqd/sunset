package import Foundation

/// The elements hidden for good on each site (roadmap 0022 W-e), as CSS selectors, kept per site (`SiteRules`): for the site
/// and its subdomains, whatever blocking says.
@MainActor
package enum HiddenElements {
    package static let shared = make()

    /// Rules kept in memory until a table is given.
    package static func make() -> SiteRules<[String]> {
        SiteRules(
            encode: { $0.joined(separator: "\u{1F}") },
            decode: { $0.split(separator: "\u{1F}").map(String.init) }
        )
    }
}

extension SiteRules where Value == [String] {
    /// The selectors hidden on `host` for a page of `profile`: its own, else all profiles' (roadmap 0050 E); nil: all
    /// profiles'. A site's own, or its nearest parent site's.
    package func selectors(for host: String?, profile: UUID? = nil) -> [String] {
        value(for: host, profile: profile) ?? []
    }

    /// Hides one more element on the site, for `profile` (nil: all profiles); once.
    package func add(_ selector: String, for host: String?, profile: UUID? = nil) {
        var all = rule(for: host, profile: profile) ?? []
        guard !all.contains(selector) else { return }
        all.append(selector)
        set(all, for: host, profile: profile)
    }

    /// Shows an element again; the site's rule goes with its last selector.
    package func remove(_ selector: String, for host: String?, profile: UUID? = nil) {
        let all = (rule(for: host, profile: profile) ?? []).filter { $0 != selector }
        set(all.isEmpty ? nil : all, for: host, profile: profile)
    }
}
