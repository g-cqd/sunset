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
    /// The selectors hidden on `host`: its own, or its nearest parent site's.
    package func selectors(for host: String?) -> [String] { value(for: host) ?? [] }

    /// Hides one more element on the site; once.
    package func add(_ selector: String, for host: String?) {
        var all = rule(for: host) ?? []
        guard !all.contains(selector) else { return }
        all.append(selector)
        set(all, for: host)
    }

    /// Shows an element again; the site's rule goes with its last selector.
    package func remove(_ selector: String, for host: String?) {
        let all = (rule(for: host) ?? []).filter { $0 != selector }
        set(all.isEmpty ? nil : all, for: host)
    }
}
