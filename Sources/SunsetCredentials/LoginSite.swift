import Foundation

/// A page's site for filling and saving (roadmap 0094 B): its registrable domain, by `registrable` (the Public Suffix
/// List); an IP address, `localhost` or a host of one label is a site of its own, as is a host the list does not cut.
/// In lower case, without a trailing dot.
public enum LoginSite {
    public static func of(_ host: String, registrable: (String) -> String?) -> String {
        var host = host.lowercased()
        if host.hasSuffix(".") { host.removeLast() }
        let isAddress = host.contains(":") || host.split(separator: ".").allSatisfy { $0.allSatisfy(\.isNumber) }
        guard !isAddress, host.contains(".") else { return host }
        return registrable(host) ?? host
    }
}
