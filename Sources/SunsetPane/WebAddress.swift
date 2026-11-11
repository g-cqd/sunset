public import Foundation

/// What is typed in a page's address field, as the address to load: an address with its scheme as it is, a host without one with `https` (`http` for
/// this machine and the local network, which rarely have a certificate), and anything else as words to search for.
public enum WebAddress {
    /// The schemes that are loaded as typed. Anything else with a colon (`javascript:`, `data:`) is searched for, not run.
    static let schemes: Set<String> = ["http", "https", "file", "about"]
    static let search = "https://duckduckgo.com/?q="

    public static func url(for text: String) -> URL? {
        let typed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !typed.isEmpty else { return nil }
        if !typed.contains(where: \.isWhitespace) {
            if let colon = typed.firstIndex(of: ":"), schemes.contains(typed[..<colon].lowercased()),
                let url = URL(string: typed)
            {
                return url
            }
            if let host = host(of: typed) {
                return URL(string: (isLocal(host) ? "http://" : "https://") + typed)
            }
        }
        var allowed = CharacterSet.urlQueryAllowed
        allowed.remove(charactersIn: "&+=?#:")
        return (typed.addingPercentEncoding(withAllowedCharacters: allowed)).flatMap { URL(string: search + $0) }
    }

    /// The host `typed` starts with, when it looks like one: `localhost`, a bracketed IPv6 address, or a name or address with a dot in it.
    private static func host(of typed: String) -> String? {
        let end = typed.firstIndex { $0 == "/" || $0 == "?" || $0 == "#" } ?? typed.endIndex
        var authority = typed[..<end]
        if authority.hasPrefix("[") {
            guard let close = authority.firstIndex(of: "]") else { return nil }
            return String(authority[...close])
        }
        if let colon = authority.lastIndex(of: ":") {
            guard authority[authority.index(after: colon)...].allSatisfy(\.isNumber) else { return nil }
            authority = authority[..<colon]
        }
        let isName = authority.allSatisfy { $0.isLetter || $0.isNumber || $0 == "." || $0 == "-" }
        guard isName, !authority.isEmpty, !authority.hasPrefix("."), !authority.hasSuffix(".") else { return nil }
        return authority == "localhost" || authority.contains(".") ? String(authority) : nil
    }

    private static func isLocal(_ host: String) -> Bool {
        if host == "localhost" || host.hasPrefix("[") || host.hasSuffix(".local") { return true }
        let parts = host.split(separator: ".")
        return parts.count == 4 && parts.allSatisfy { UInt8($0) != nil }
    }
}
