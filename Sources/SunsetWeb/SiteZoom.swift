import Foundation
package import SunsetStorage

/// The zoom each site was given (web step d, `web.zoomScope`): by host, kept as sealed records of the state database when
/// remembered (R12 step ST-3), or in memory until the app quits. 100% is not kept.
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
    package var count: Int { levels.count }

    /// The levels are kept from one run to the next.
    package var remembers: Bool { table != nil }

    package func level(for host: String?) -> Double {
        guard let host = host.map(Self.key) else { return 1 }
        return levels[host] ?? 1
    }

    package func set(_ level: Double, for host: String?, remember: Bool) {
        guard let host = host.map(Self.key) else { return }
        if abs(level - 1) < 0.001 { levels[host] = nil } else { levels[host] = level }
        if remember { keep(host) }
    }

    /// Forgets every site's level (Clear History).
    package func clearAll() {
        levels = [:]
        table?.removeAll()
    }

    /// One entry for a site with or without "www.".
    static func key(_ host: String) -> String {
        let lower = host.lowercased()
        return lower.hasPrefix("www.") ? String(lower.dropFirst(4)) : lower
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
        for row in table?.all().rows ?? [] {
            guard let text = String(data: row.payload, encoding: .utf8) else { continue }
            let parts = text.split(separator: "\n", maxSplits: 1)
            if parts.count == 2, let level = Double(parts[1]) { levels[String(parts[0])] = level }
        }
    }

    private func keep(_ host: String) {
        guard let level = levels[host] else {
            table?.remove(host)
            return
        }
        table?.put(host, payload: Data("\(host)\n\(level)".utf8))
    }
}
