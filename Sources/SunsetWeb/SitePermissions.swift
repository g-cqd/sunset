package import Foundation
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
        didSet {
            load()
        }
    }

    /// The answers it shares (a profile's pages, roadmap 0050), its defaults its own.
    @ObservationIgnored private var base: SitePermissions?

    /// Answers of `base`, defaults of its own.
    /// `profile`: the answers given from its pages are its own (roadmap 0050 E), kept as `<profile>|<host>` in `base`; a
    /// site it never answered falls to all profiles' answer, then to its defaults.
    package static func sharing(
        _ base: SitePermissions,
        defaults: [SitePermission: PermissionAnswer],
        profile: UUID? = nil
    ) -> SitePermissions {
        let own = SitePermissions()
        own.defaults = defaults
        own.base = base
        own.profile = profile
        return own
    }

    /// The profile whose answers it gives and keeps first (a profile's pages).
    @ObservationIgnored package private(set) var profile: UUID?

    private func profileKey(_ host: String) -> String? {
        profile.map { $0.uuidString + "|" + Self.key(host) }
    }

    package init(table: SealedTable? = nil) {
        self.table = table
        load()
    }

    package func answer(_ permission: SitePermission, for host: String?) -> PermissionAnswer {
        let answers = base?.answers ?? self.answers
        if let host, let key = profileKey(host), let kept = answers[key]?[permission] { return kept }
        if let host, let kept = answers[Self.key(host)]?[permission] { return kept }
        return defaults[permission] ?? permission.defaultAnswer
    }

    /// The answer for `host`; nil forgets it (the default applies again).
    package func set(_ answer: PermissionAnswer?, _ permission: SitePermission, for host: String) {
        if let base {
            if let key = profileKey(host) {
                base.setKey(answer, permission, key: key)
            } else {
                base.set(answer, permission, for: host)
            }
            return
        }
        let key = Self.key(host)
        answers[key, default: [:]][permission] = answer
        if answers[key]?.isEmpty == true { answers[key] = nil }
        keep(key)
    }

    private func setKey(_ answer: PermissionAnswer?, _ permission: SitePermission, key: String) {
        answers[key, default: [:]][permission] = answer
        if answers[key]?.isEmpty == true { answers[key] = nil }
        keep(key)
    }

    /// The answers of `profile` (nil: all profiles'), by host.
    private func answers(of profile: UUID?) -> [String: [SitePermission: PermissionAnswer]] {
        let prefix = profile.map { $0.uuidString + "|" }
        var mine: [String: [SitePermission: PermissionAnswer]] = [:]
        for (key, kept) in answers {
            if let prefix {
                if key.hasPrefix(prefix) { mine[String(key.dropFirst(prefix.count))] = kept }
            } else if !key.contains("|") {
                mine[key] = kept
            }
        }
        return mine
    }

    /// The sites with an answer of their own, and how many; `profile`: its own (nil: all profiles').
    package func answeredSites(profile: UUID? = nil) -> [(host: String, count: Int)] {
        answers(of: profile).map { ($0.key, $0.value.count) }.sorted { $0.host < $1.host }
    }

    package var answeredSites: [(host: String, count: Int)] {
        answeredSites()
    }

    /// The sites answered for `permission`, by name; `profile`: its own (nil: all profiles').
    package func sites(for permission: SitePermission, profile: UUID? = nil) -> [(
        host: String, answer: PermissionAnswer
    )] {
        answers(of: profile).compactMap { host, kept in kept[permission].map { (host, $0) } }
            .sorted { $0.host < $1.host }
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
