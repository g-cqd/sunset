import Foundation
package import Observation
package import SunsetStorage

/// The answers sites were given (web step g): Allow and Deny by host, kept as sealed records of the state database (R12 step ST-3); Allow Once is never kept. A permission no
/// site was answered for falls to its default (`web.permissions.*`).
@MainActor @Observable
package final class SitePermissions {
    package static let shared = SitePermissions()

    package private(set) var answers: [String: [SitePermission: PermissionAnswer]] = [:]
    package var defaults: [SitePermission: PermissionAnswer] = [:]
    @ObservationIgnored package var table: SealedTable? {
        didSet { load() }
    }

    package init(table: SealedTable? = nil) {
        self.table = table
        load()
    }

    package func answer(_ permission: SitePermission, for host: String?) -> PermissionAnswer {
        if let host, let kept = answers[Self.key(host)]?[permission] { return kept }
        return defaults[permission] ?? permission.defaultAnswer
    }

    /// The answer for `host`; nil forgets it (the default applies again).
    package func set(_ answer: PermissionAnswer?, _ permission: SitePermission, for host: String) {
        let key = Self.key(host)
        answers[key, default: [:]][permission] = answer
        if answers[key]?.isEmpty == true { answers[key] = nil }
        keep(key)
    }

    /// The sites answered for `permission`, by name.
    package func sites(for permission: SitePermission) -> [(host: String, answer: PermissionAnswer)] {
        answers.compactMap { host, kept in kept[permission].map { (host, $0) } }.sorted { $0.host < $1.host }
    }

    package func clearAll() {
        answers = [:]
        table?.removeAll()
    }

    static func key(_ host: String) -> String {
        let lower = host.lowercased()
        return lower.hasPrefix("www.") ? String(lower.dropFirst(4)) : lower
    }

    /// One site's answers as they are kept.
    private struct Kept: Codable {
        var host: String
        var answers: [String: PermissionAnswer]
    }

    /// Takes in the answers of the file of before the database (`site-permissions.json`); says how many sites, or nil when
    /// there is none.
    package func importLegacy(at path: String) -> Int? {
        guard let data = FileManager.default.contents(atPath: path),
            let read = try? JSONDecoder().decode([String: [String: PermissionAnswer]].self, from: data)
        else { return nil }
        for (host, kept) in read where answers[host] == nil {
            answers[host] = Self.answers(kept)
            keep(host)
        }
        return read.count
    }

    private static func answers(_ kept: [String: PermissionAnswer]) -> [SitePermission: PermissionAnswer] {
        Dictionary(
            uniqueKeysWithValues: kept.compactMap { key, answer in SitePermission(rawValue: key).map { ($0, answer) } }
        )
    }

    private func load() {
        answers = [:]
        for row in table?.all().rows ?? [] {
            guard let kept = try? JSONDecoder().decode(Kept.self, from: row.payload) else { continue }
            answers[kept.host] = Self.answers(kept.answers)
        }
    }

    private func keep(_ host: String) {
        guard let kept = answers[host], !kept.isEmpty else {
            table?.remove(host)
            return
        }
        let plain = Dictionary(uniqueKeysWithValues: kept.map { ($0.key.rawValue, $0.value) })
        guard let data = try? JSONEncoder().encode(Kept(host: host, answers: plain)) else { return }
        table?.put(host, payload: data)
    }
}
