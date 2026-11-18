import Foundation
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

    /// The value for `host`: its own rule, else the rule of the nearest site it is a subdomain of.
    package func value(for host: String?) -> Value? {
        guard let host = host.map(SiteHost.key) else { return nil }
        if let own = values[host] { return own }
        var labels = host.split(separator: ".").dropFirst()
        while labels.count > 1 {
            if let value = values[labels.joined(separator: ".")] { return value }
            labels = labels.dropFirst()
        }
        return nil
    }

    /// The rule of exactly this site.
    package func rule(for host: String?) -> Value? { host.flatMap { values[SiteHost.key($0)] } }

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

    package func clearAll() {
        values = [:]
        table?.removeAll()
    }

    private func load() {
        for row in table?.all().rows ?? [] {
            guard let text = String(data: row.payload, encoding: .utf8) else { continue }
            let parts = text.split(separator: "\n", maxSplits: 1)
            if parts.count == 2, let value = decode(String(parts[1])) { values[String(parts[0])] = value }
        }
    }
}
