import Foundation

/// A link of an authenticator (`otpauth://`, `otpauth-migration://`): its parts when it is of `scheme`, its query's
/// names lowercased (the first of each).
enum OTPLink {
    static func read(_ text: String, scheme: String) -> (host: String, path: String, query: [String: String])? {
        guard let parts = URLComponents(string: text), parts.scheme?.lowercased() == scheme else { return nil }
        let query = Dictionary((parts.queryItems ?? []).map { ($0.name.lowercased(), $0.value ?? "") }) { first, _ in
            first
        }
        return (parts.host?.lowercased() ?? "", parts.path, query)
    }
}
