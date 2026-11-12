import Foundation

/// The zoom each site was given (web step d, `web.zoomScope`): by host, kept in a file beside the session when remembered, or in memory until the
/// app quits. 100% is not kept.
@MainActor
package final class SiteZoom {
    package static let shared = SiteZoom()

    /// Where the levels are written; nil: kept in memory only (the session scope, and tests).
    package var path: String? {
        didSet {
            levels = [:]
            load()
        }
    }
    private var levels: [String: Double] = [:]

    package init(path: String? = nil) {
        self.path = path
        load()
    }

    package func level(for host: String?) -> Double {
        guard let host = host.map(Self.key) else { return 1 }
        return levels[host] ?? 1
    }

    package func set(_ level: Double, for host: String?, remember: Bool) {
        guard let host = host.map(Self.key) else { return }
        if abs(level - 1) < 0.001 { levels[host] = nil } else { levels[host] = level }
        if remember { save() }
    }

    /// One entry for a site with or without "www.".
    static func key(_ host: String) -> String {
        let lower = host.lowercased()
        return lower.hasPrefix("www.") ? String(lower.dropFirst(4)) : lower
    }

    private func load() {
        guard let path, let data = FileManager.default.contents(atPath: path),
            let read = try? JSONDecoder().decode([String: Double].self, from: data)
        else { return }
        levels = read
    }

    private func save() {
        guard let path, let data = try? JSONEncoder().encode(levels) else { return }
        let url = URL(fileURLWithPath: path)
        try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? data.write(to: url, options: .atomic)
    }
}
