import Foundation
package import Observation
package import SunsetStorage

/// The browser each site is shown (roadmap 0022, W-a): by host, for the site and its subdomains, kept as sealed records
/// of the state database, or in memory until the app quits. A site with no rule is shown the default (`web.agent`).
@MainActor @Observable
package final class SiteAgents {
    package static let shared = SiteAgents()

    /// Where the rules are kept; nil: in memory only (tests, a run with no key).
    @ObservationIgnored package var table: SealedTable? {
        didSet {
            agents = [:]
            load()
        }
    }
    private var agents: [String: BrowserAgent] = [:]

    package init(table: SealedTable? = nil) {
        self.table = table
        load()
    }

    /// The rules, by host.
    package var rules: [(host: String, agent: BrowserAgent)] {
        agents.sorted { $0.key < $1.key }.map { ($0.key, $0.value) }
    }

    /// What `host` is shown: its own rule, else the rule of the nearest site it is a subdomain of, else `fallback`. A
    /// rule is never for a bare last label ("com").
    package func agent(for host: String?, default fallback: BrowserAgent) -> BrowserAgent {
        guard let host = host.map(Self.key) else { return fallback }
        if let own = agents[host] { return own }
        var labels = host.split(separator: ".").dropFirst()
        while labels.count > 1 {
            if let agent = agents[labels.joined(separator: ".")] { return agent }
            labels = labels.dropFirst()
        }
        return fallback
    }

    /// The rule of exactly this site, if it has one.
    package func rule(for host: String?) -> BrowserAgent? { host.flatMap { agents[Self.key($0)] } }

    /// Gives a site a rule, or takes it away (nil): it is then shown the default.
    package func set(_ agent: BrowserAgent?, for host: String?) {
        guard let host = host.map(Self.key), !host.isEmpty else { return }
        agents[host] = agent
        if let agent {
            table?.put(host, payload: Data("\(host)\n\(agent.rawValue)".utf8))
        } else {
            table?.remove(host)
        }
    }

    package func clearAll() {
        agents = [:]
        table?.removeAll()
    }

    /// One entry for a site with or without "www.".
    static func key(_ host: String) -> String {
        let lower = host.lowercased()
        return lower.hasPrefix("www.") ? String(lower.dropFirst(4)) : lower
    }

    private func load() {
        for row in table?.all().rows ?? [] {
            guard let text = String(data: row.payload, encoding: .utf8) else { continue }
            let parts = text.split(separator: "\n", maxSplits: 1)
            if parts.count == 2, let agent = BrowserAgent(rawValue: String(parts[1])) {
                agents[String(parts[0])] = agent
            }
        }
    }
}
