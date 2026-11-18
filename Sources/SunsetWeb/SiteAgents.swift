import Foundation
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
        get { store.table }
        set { store.table = newValue }
    }

    /// The rules, by host.
    package var rules: [(host: String, agent: BrowserAgent)] { store.rules.map { ($0.host, $0.value) } }

    /// What `host` is shown: its own rule, else the rule of the nearest site it is a subdomain of, else `fallback`. A
    /// rule is never for a bare last label ("com").
    package func agent(for host: String?, default fallback: BrowserAgent) -> BrowserAgent {
        store.value(for: host) ?? fallback
    }

    /// The rule of exactly this site, if it has one.
    package func rule(for host: String?) -> BrowserAgent? { store.rule(for: host) }

    /// Gives a site a rule, or takes it away (nil): it is then shown the default.
    package func set(_ agent: BrowserAgent?, for host: String?) { store.set(agent, for: host) }

    package func clearAll() { store.clearAll() }
}
