public import Foundation

/// Apple's password-manager-resources (github.com/apple/password-manager-resources, MIT; task t118): per-site password
/// rules, the sites that share logins, change-password pages. Each is looked up from a host, then each parent up to its
/// registrable domain (the Public Suffix List's).
public struct PasswordManagerResources: Sendable {
    private let rules: [String: String]
    private let changePages: [String: URL]
    /// For a site, the sites whose logins are offered on it (itself not included).
    private let offered: [String: Set<String>]
    private let suffixes: PublicSuffixList

    /// Reads the three files' JSON; a file that does not read gives nothing of its kind.
    public init(passwordRules: Data, sharedCredentials: Data, changePasswordURLs: Data, suffixes: PublicSuffixList) {
        let rules = (try? JSONSerialization.jsonObject(with: passwordRules)) as? [String: [String: Any]] ?? [:]
        self.rules = rules.compactMapValues { $0["password-rules"] as? String }
        let pages = (try? JSONSerialization.jsonObject(with: changePasswordURLs)) as? [String: String] ?? [:]
        changePages = pages.compactMapValues(URL.init(string:))
        let groups = (try? JSONSerialization.jsonObject(with: sharedCredentials)) as? [[String: Any]] ?? []
        var offered: [String: Set<String>] = [:]
        for group in groups {
            if let shared = group["shared"] as? [String] {
                for site in shared { offered[site, default: []].formUnion(shared.filter { $0 != site }) }
            } else if let from = group["from"] as? [String], let to = group["to"] as? [String] {
                for site in to { offered[site, default: []].formUnion(from) }
            }
        }
        self.offered = offered
        self.suffixes = suffixes
    }

    /// The `passwordrules` text for `host`'s site, if the site has one.
    public func passwordRules(for host: String) -> String? {
        lookUp(host) { rules[$0] }
    }

    /// The sites whose saved logins may be offered on `host`: its own site and those sharing with it.
    public func loginSites(for host: String) -> Set<String> {
        let site = suffixes.registrableDomain(of: host) ?? host.lowercased()
        return (lookUp(host) { offered[$0] } ?? []).union([site])
    }

    /// The page where `host`'s site lets a person change their password.
    public func changePasswordPage(for host: String) -> URL? {
        lookUp(host) { changePages[$0] }
    }

    /// The first value for `host`, then each parent down to its registrable domain.
    /// - Complexity: O(the host's labels).
    private func lookUp<Value>(_ host: String, _ value: (String) -> Value?) -> Value? {
        var name = host.lowercased()
        let site = suffixes.registrableDomain(of: name)
        while true {
            if let found = value(name) { return found }
            guard name != site, let dot = name.firstIndex(of: "."), site != nil else { return nil }
            name = String(name[name.index(after: dot)...])
        }
    }
}
