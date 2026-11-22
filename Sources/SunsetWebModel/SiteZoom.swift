package import Foundation
package import SunsetStorage

/// The zoom each site was given (`web.zoomScope`): by host, kept as sealed records of the state database when
/// remembered, or in memory until the app quits. 100% is not kept.
@MainActor
package final class SiteZoom {
    package static let shared = SiteZoom()

    /// Where the levels are kept; nil: in memory only (the session scope, and tests).
    package var table: SealedTable? {
        didSet {
            levels = [:]
            load()
        }
    }
    private var levels: [String: Double] = [:]

    package init(table: SealedTable? = nil) {
        self.table = table
        load()
    }

    /// How many sites have a level of their own.
    package var count: Int {
        levels.count
    }
    /// The sites with a level of their own, and it.
    package var sites: [(host: String, level: Double)] {
        sites(profile: nil)
    }

    /// A profile's own levels, kept as `<profile>|<host>`; nil: all profiles'.
    package func sites(profile: UUID?) -> [(host: String, level: Double)] {
        let prefix = profile.map { $0.uuidString + "|" }
        return
            levels.compactMap { key, level in
                if let prefix { return key.hasPrefix(prefix) ? (String(key.dropFirst(prefix.count)), level) : nil }
                return key.contains("|") ? nil : (key, level)
            }
            .sorted { $0.host < $1.host }
    }

    /// The levels are kept from one run to the next.
    package var remembers: Bool {
        table != nil
    }

    package func level(for host: String?, profile: UUID? = nil) -> Double {
        guard let host = host.map(Self.key) else { return 1 }
        if let profile, let own = levels[profile.uuidString + "|" + host] { return own }
        return levels[host] ?? 1
    }

    package func set(_ level: Double, for host: String?, remember: Bool, profile: UUID? = nil) {
        guard let site = host.map(Self.key) else { return }
        let host = profile.map { $0.uuidString + "|" + site } ?? site
        if abs(level - 1) < 0.001 { levels[host] = nil } else { levels[host] = level }
        if remember { keep(host) }
    }

    /// Forgets every site's level (Clear History).
    package func clearAll() {
        levels = [:]
        table?.removeAll()
    }

    /// One entry for a site with or without "www." (`SiteHost`).
    package static func key(_ host: String) -> String {
        SiteHost.key(host)
    }

    /// Takes in the levels of the file of before the database (`site-zoom.json`); says how many, or nil when there is none.
    package func importLegacy(at path: String) -> Int? {
        guard let data = FileManager.default.contents(atPath: path),
            let read = try? JSONDecoder().decode([String: Double].self, from: data)
        else { return nil }
        for (host, level) in read where levels[host] == nil {
            levels[host] = level
            keep(host)
        }
        return read.count
    }

    private func load() {
        for (host, text) in table?.pairs() ?? [] {
            if let level = Double(text) { levels[host] = level }
        }
    }

    private func keep(_ host: String) {
        guard let level = levels[host] else {
            table?.remove(host)
            return
        }
        table?.put(host, value: "\(level)")
    }
}
