package import Foundation
package import SunsetStorage

/// The browser each site is shown (roadmap 0022, W-a): by host, for the site and its subdomains, kept as sealed records
/// of the state database, or in memory until the app quits. A site with no rule is shown the default (`web.agent`).
@MainActor
package final class SiteAgents {
    package static let shared = SiteAgents()

    private let store: SiteRules<BrowserAgent>

    package init(table: SealedTable? = nil) {
        store = SiteRules(table: table, allowsBareLabel: true, encode: \.rawValue, decode: BrowserAgent.init(rawValue:))
    }

    /// Where the rules are kept; nil: in memory only (tests, a run with no key).
    package var table: SealedTable? {
        get {
            store.table
        }
        set {
            store.table = newValue
        }
    }

    /// The rules, by host.
    package var rules: [(host: String, agent: BrowserAgent)] {
        store.rules.map { ($0.host, $0.value) }
    }

    /// What `host` is shown: its own rule, else the rule of the nearest site it is a subdomain of, else `fallback`. A
    /// rule is never for a bare last label ("com").
    package func agent(for host: String?, default fallback: BrowserAgent) -> BrowserAgent {
        store.value(for: host) ?? fallback
    }

    /// What the page at `url` is shown: the most specific rule for it (an address prefix, its host, a pattern; note n40).
    /// `profile`: a page of that profile, its own rule first (roadmap 0050 E); nil: all profiles'.
    package func agent(for url: URL, default fallback: BrowserAgent, profile: UUID? = nil) -> BrowserAgent {
        store.value(for: url, profile: profile) ?? fallback
    }

    /// Gives a pattern a rule, or takes it away.
    package func set(_ agent: BrowserAgent?, for pattern: SitePattern, profile: UUID? = nil) {
        store.set(agent, for: pattern, profile: profile)
    }

    /// The rule of exactly this site, if it has one.
    package func rule(for host: String?, profile: UUID? = nil) -> BrowserAgent? {
        store.rule(for: host, profile: profile)
    }

    /// Gives a site a rule, or takes it away (nil): it is then shown the default.
    package func set(_ agent: BrowserAgent?, for host: String?, profile: UUID? = nil) {
        store.set(agent, for: host, profile: profile)
    }

    /// A profile's own rules (nil: all profiles').
    package func rules(profile: UUID?) -> [(host: String, agent: BrowserAgent)] {
        store.rules(profile: profile).map { ($0.host, $0.value) }
    }

    package func clearAll() {
        store.clearAll()
    }
}
