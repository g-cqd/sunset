import Foundation
package import Observation

/// The answers sites were given (web step g): Allow and Deny by host, kept in a file beside the session; Allow Once is never kept. A permission no
/// site was answered for falls to its default (`web.permissions.*`).
@MainActor @Observable
package final class SitePermissions {
    package static let shared = SitePermissions()

    package private(set) var answers: [String: [SitePermission: PermissionAnswer]] = [:]
    package var defaults: [SitePermission: PermissionAnswer] = [:]
    @ObservationIgnored package var path: String? {
        didSet { load() }
    }

    package init(path: String? = nil) {
        self.path = path
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
        save()
    }

    /// The sites answered for `permission`, by name.
    package func sites(for permission: SitePermission) -> [(host: String, answer: PermissionAnswer)] {
        answers.compactMap { host, kept in kept[permission].map { (host, $0) } }.sorted { $0.host < $1.host }
    }

    package func clearAll() {
        answers = [:]
        save()
    }

    static func key(_ host: String) -> String {
        let lower = host.lowercased()
        return lower.hasPrefix("www.") ? String(lower.dropFirst(4)) : lower
    }

    private func load() {
        answers = [:]
        guard let path, let data = FileManager.default.contents(atPath: path),
            let read = try? JSONDecoder().decode([String: [String: PermissionAnswer]].self, from: data)
        else { return }
        for (host, kept) in read {
            answers[host] = Dictionary(
                uniqueKeysWithValues: kept.compactMap { key, answer in
                    SitePermission(rawValue: key).map { ($0, answer) }
                }
            )
        }
    }

    private func save() {
        guard let path else { return }
        let plain = answers.mapValues { kept in
            Dictionary(uniqueKeysWithValues: kept.map { ($0.key.rawValue, $0.value) })
        }
        guard let data = try? JSONEncoder().encode(plain) else { return }
        let url = URL(fileURLWithPath: path)
        try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? data.write(to: url, options: .atomic)
    }
}
