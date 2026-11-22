import Foundation

/// A link of an authenticator (`otpauth://`, `otpauth-migration://`, `steam://`), read as it comes: around spaces,
/// quotes or angle brackets; the scheme in any case, with `//` or without; its query's names lowercased (the first of each),
/// values decoded.
enum OTPLink {
    static func read(_ text: String, scheme: String) -> (host: String, path: String, query: [String: String])? {
        var trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines.union(CharacterSet(charactersIn: "<>\"'")))
        // "otpauth:totp/…": the slashes a writer left out.
        let prefix = scheme + ":"
        if trimmed.lowercased().hasPrefix(prefix), !trimmed.dropFirst(prefix.count).hasPrefix("//") {
            trimmed = prefix + "//" + trimmed.dropFirst(prefix.count)
        }
        guard let parts = URLComponents(string: trimmed), parts.scheme?.lowercased() == scheme else { return nil }
        let query = Dictionary((parts.queryItems ?? []).map { ($0.name.lowercased(), $0.value ?? "") }) { first, _ in
            first
        }
        return (parts.host?.lowercased() ?? "", parts.path, query)
    }
}
