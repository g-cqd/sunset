import Foundation

/// The Public Suffix List (publicsuffix.org, MPL 2.0; task t118): which part of a host name a registry, not a site, owns.
/// `example.co.uk`'s site is `example.co.uk`, not `co.uk`; `foo.github.io`'s is itself. Rules are matched on lowercase
/// labels, punycode decoded (`xn--…`); an answer keeps the form the host was given in.
public struct PublicSuffixList: Sendable {
    private let rules: Set<String>
    private let wildcards: Set<String>
    private let exceptions: Set<String>

    public var ruleCount: Int {
        rules.count + wildcards.count + exceptions.count
    }

    /// Reads the list's text: one rule a line, `//` comments, `*.` wildcards, `!` exceptions.
    /// - Complexity: O(the text).
    public init(text: String) {
        var rules = Set<String>()
        var wildcards = Set<String>()
        var exceptions = Set<String>()
        for line in text.split(whereSeparator: \.isNewline) {
            guard let word = line.split(whereSeparator: \.isWhitespace).first, !word.hasPrefix("//") else { continue }
            let rule = word.lowercased()
            if rule.hasPrefix("!") {
                exceptions.insert(String(rule.dropFirst()))
            } else if rule.hasPrefix("*.") {
                wildcards.insert(String(rule.dropFirst(2)))
            } else {
                rules.insert(rule)
            }
        }
        self.rules = rules
        self.wildcards = wildcards
        self.exceptions = exceptions
    }

    /// The registry's part of `host`; nil for no host, or one with an empty label.
    public func publicSuffix(of host: String?) -> String? {
        guard let labels = Self.labels(host) else { return nil }
        let length = suffixLength(labels.matched)
        return labels.given.suffix(length).joined(separator: ".")
    }

    /// The site's part of `host`: its public suffix and one label more; nil when `host` is a public suffix itself.
    /// - Complexity: O(the labels), each a set look-up.
    public func registrableDomain(of host: String?) -> String? {
        guard let labels = Self.labels(host) else { return nil }
        let length = suffixLength(labels.matched)
        guard length < labels.given.count else { return nil }
        return labels.given.suffix(length + 1).joined(separator: ".")
    }

    /// How many labels, from the right, the prevailing rule covers: an exception's less one, else the longest match, else
    /// one (the list's implicit `*`).
    private func suffixLength(_ labels: [String]) -> Int {
        var longest = 1
        var exception: Int?
        for count in 1 ... labels.count {
            let suffix = labels.suffix(count).joined(separator: ".")
            if exceptions.contains(suffix) { exception = count }
            if rules.contains(suffix) { longest = max(longest, count) }
            if count >= 2, wildcards.contains(labels.suffix(count - 1).joined(separator: ".")) {
                longest = max(longest, count)
            }
        }
        return exception.map { $0 - 1 } ?? longest
    }

    /// The host's labels lowercased as given, and as matched (punycode decoded); nil for none or an empty label.
    private static func labels(_ host: String?) -> (given: [String], matched: [String])? {
        guard var host = host?.lowercased(), !host.isEmpty else { return nil }
        if host.hasSuffix(".") { host.removeLast() }
        let given = host.split(separator: ".", omittingEmptySubsequences: false).map(String.init)
        guard !given.isEmpty, !given.contains(where: \.isEmpty) else { return nil }
        let matched = given.map { label in
            label.hasPrefix("xn--") ? (Punycode.decode(label.dropFirst(4)) ?? label) : label
        }
        return (given, matched)
    }
}
