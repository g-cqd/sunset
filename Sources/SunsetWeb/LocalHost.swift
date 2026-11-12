import Foundation

/// This machine and the local network (R1): reached over http at once, never sent for suggestions, not marked Not Secure.
package enum LocalHost {
    /// The host part of something typed without a scheme ("nas:8080/a" is "nas").
    static func host(of text: String) -> String {
        if text.hasPrefix("[") { return text.split(separator: "]").first.map { String($0) + "]" } ?? text }
        return String(text.prefix { $0 != "/" && $0 != ":" && $0 != "?" && $0 != "#" }).lowercased()
    }

    package static func isLocal(_ rawHost: String) -> Bool {
        let host = rawHost.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: "[]"))
        if host == "localhost" || host.hasSuffix(".localhost") || host.hasSuffix(".local") || host == "::1" {
            return true
        }
        let parts = host.split(separator: ".").compactMap { Int($0) }
        guard parts.count == 4, host.split(separator: ".").count == 4, parts.allSatisfy({ (0 ... 255).contains($0) })
        else {
            return false
        }
        switch (parts[0], parts[1]) {
            case (127, _), (10, _), (192, 168), (169, 254): return true
            case (172, let second): return (16 ... 31).contains(second)
            default: return false
        }
    }
}
