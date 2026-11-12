/// A site's standing answer, or the default for sites not answered yet.
package enum PermissionAnswer: String, CaseIterable, Codable, Sendable {
    case ask, allow, deny

    package var title: String {
        switch self {
            case .ask: "Ask"
            case .allow: "Allow"
            case .deny: "Deny"
        }
    }
}
