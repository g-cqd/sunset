package import Foundation
package import Observation
package import SunsetStorage

/// A value per site (the browser it is shown, the Space it opens in): by host, for the site and its subdomains, kept as
/// sealed records of the state database (`host\nvalue`), or in memory until the app quits. Never for a bare last label.
@MainActor @Observable
package final class SiteRules<Value: Sendable> {
    /// Where the rules are kept; nil: in memory only (tests, a run with no key).
    @ObservationIgnored package var table: SealedTable? {
        didSet {
            values = [:]
            load()
        }
    }
    private var values: [String: Value] = [:]
    /// Each profile's own (roadmap 0050 E), kept as `<profile>|<key>`.
    private var own: [UUID: [String: Value]] = [:]
    @ObservationIgnored private let encode: (Value) -> String
    @ObservationIgnored private let decode: (String) -> Value?
    /// A rule may be for a bare last label ("localhost"): the browser a site is shown, as before.
    @ObservationIgnored private let allowsBareLabel: Bool

    package init(
        table: SealedTable? = nil,
        allowsBareLabel: Bool = false,
        encode: @escaping (Value) -> String,
        decode: @escaping (String) -> Value?
    ) {
        self.encode = encode
        self.decode = decode
        self.allowsBareLabel = allowsBareLabel
        self.table = table
        load()
    }

    /// The rules, by host.
    package var rules: [(host: String, value: Value)] {
        values.sorted { $0.key < $1.key }.map { ($0.key, $0.value) }
    }

    /// The value for `host`: its own rule, else the rule of the nearest site it is a subdomain of, else a pattern's.
    package func value(for host: String?) -> Value? {
        guard let host = host.map(SiteHost.key), !host.isEmpty else { return nil }
        if let own = values[host] { return own }
        var parts = URLComponents()
        parts.scheme = "https"
        parts.host = host
        parts.path = "/"
        return parts.url.flatMap { value(for: $0) }
    }

    /// The value for an address: the most specific rule that matches it (`SitePattern`; the owner's note n40).
    package func value(for url: URL) -> Value? {
        best(in: values, for: url)
    }

    private func best(in values: [String: Value], for url: URL) -> Value? {
        var best: (score: Int, value: Value)?
        for (key, value) in values {
            guard let pattern = SitePattern(key) ?? (allowsBareLabel ? .site(key) : nil),
                let score = Self.score(pattern, key: key, url: url)
            else { continue }
            if best.map({ score > $0.score }) ?? true { best = (score, value) }
        }
        return best?.value
    }

    /// A bare label ("localhost") is matched as itself: `SitePattern` reads none.
    private static func score(_ pattern: SitePattern, key: String, url: URL) -> Int? {
        if !key.contains("."), !key.contains("://") {
            return url.host().map(SiteHost.key) == key ? 10_000 : nil
        }
        return pattern.specificity(for: url)
    }

    /// Gives a pattern a rule, or takes it away (nil).
    package func set(_ value: Value?, for pattern: SitePattern) {
        let key = pattern.key
        values[key] = value
        if let value {
            table?.put(key, payload: Data("\(key)\n\(encode(value))".utf8))
        } else {
            table?.remove(key)
        }
    }

    /// The rule of exactly this site.
    package func rule(for host: String?) -> Value? {
        host.flatMap { values[SiteHost.key($0)] }
    }

    /// Gives a site a rule, or takes it away (nil).
    package func set(_ value: Value?, for host: String?) {
        guard let host = host.map(SiteHost.key), !host.isEmpty, value == nil || host.contains(".") || allowsBareLabel
        else { return }
        values[host] = value
        if let value {
            table?.put(host, payload: Data("\(host)\n\(encode(value))".utf8))
        } else {
            table?.remove(host)
        }
    }

    // MARK: A profile's own (roadmap 0050 E)

    /// For a page of `profile`: its own rule, else all profiles'. Nil: all profiles' only (the first profile's pages).
    package func value(for host: String?, profile: UUID?) -> Value? {
        guard let profile, let host = host.map(SiteHost.key), !host.isEmpty else { return value(for: host) }
        var parts = URLComponents()
        parts.scheme = "https"
        parts.host = host
        parts.path = "/"
        if let mine = own[profile]?[host] { return mine }
        return parts.url.flatMap { value(for: $0, profile: profile) } ?? value(for: host)
    }

    package func value(for url: URL, profile: UUID?) -> Value? {
        if let profile, let mine = own[profile], let found = best(in: mine, for: url) { return found }
        return value(for: url)
    }

    /// The rule of exactly this site, the profile's own (nil: all profiles').
    package func rule(for host: String?, profile: UUID?) -> Value? {
        guard let profile else { return rule(for: host) }
        return host.flatMap { own[profile]?[SiteHost.key($0)] }
    }

    /// A profile's own rules (nil: all profiles').
    package func rules(profile: UUID?) -> [(host: String, value: Value)] {
        guard let profile else { return rules }
        return (own[profile] ?? [:]).sorted { $0.key < $1.key }.map { ($0.key, $0.value) }
    }

    package func set(_ value: Value?, for host: String?, profile: UUID?) {
        guard let profile else { return set(value, for: host) }
        guard let host = host.map(SiteHost.key), !host.isEmpty, value == nil || host.contains(".") || allowsBareLabel
        else { return }
        setOwn(value, key: host, profile: profile)
    }

    package func set(_ value: Value?, for pattern: SitePattern, profile: UUID?) {
        guard let profile else { return set(value, for: pattern) }
        setOwn(value, key: pattern.key, profile: profile)
    }

    private func setOwn(_ value: Value?, key: String, profile: UUID) {
        own[profile, default: [:]][key] = value
        let stored = profile.uuidString + "|" + key
        if let value {
            table?.put(stored, payload: Data("\(stored)\n\(encode(value))".utf8))
        } else {
            table?.remove(stored)
        }
    }

    package func clearAll() {
        values = [:]
        own = [:]
        table?.removeAll()
    }

    private func load() {
        for row in table?.all().rows ?? [] {
            guard let text = String(data: row.payload, encoding: .utf8) else { continue }
            let parts = text.split(separator: "\n", maxSplits: 1)
            guard parts.count == 2, let value = decode(String(parts[1])) else { continue }
            let key = String(parts[0])
            // A profile's own: `<profile>|<key>`.
            if let bar = key.firstIndex(of: "|"), let profile = UUID(uuidString: String(key[..<bar])) {
                own[profile, default: [:]][String(key[key.index(after: bar)...])] = value
            } else {
                values[key] = value
            }
        }
    }
}
