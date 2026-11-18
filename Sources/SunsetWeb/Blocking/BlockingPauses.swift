import Foundation
package import Observation
package import SunsetStorage

/// The sites blocking is paused on (roadmap 0022 W-c), from a site's panel: for the site and its subdomains, kept as sealed
/// records of the state database, or in memory until the app quits. Never a bare last label ("com").
@MainActor @Observable
package final class BlockingPauses {
    /// Where the pauses are kept; nil: in memory only (tests, a run with no key).
    @ObservationIgnored package var table: SealedTable? {
        didSet {
            hosts = []
            load()
        }
    }
    private var hosts: Set<String> = []

    package init(table: SealedTable? = nil) {
        self.table = table
        load()
    }

    package var paused: [String] { hosts.sorted() }

    /// Whether blocking is paused on `host`: it or a site it is a subdomain of.
    package func isPaused(_ host: String?) -> Bool {
        guard let host = host.map(SiteHost.key) else { return false }
        var labels = host.split(separator: ".")[...]
        while labels.count > 1 {
            if hosts.contains(labels.joined(separator: ".")) { return true }
            labels = labels.dropFirst()
        }
        return false
    }

    /// Pauses blocking on a site, or takes the pause away.
    package func set(_ paused: Bool, for host: String?) {
        guard let host = host.map(SiteHost.key), host.contains(".") else { return }
        if paused {
            hosts.insert(host)
            table?.put(host, payload: Data(host.utf8))
        } else {
            hosts.remove(host)
            table?.remove(host)
        }
    }

    package func clearAll() {
        hosts = []
        table?.removeAll()
    }

    private func load() {
        for row in table?.all().rows ?? [] {
            if let host = String(data: row.payload, encoding: .utf8) { hosts.insert(host) }
        }
    }
}
