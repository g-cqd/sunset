/// How the history is listed with several profiles: every page, the current profile's only, or under each profile.
package enum HistoryProfiles: String, CaseIterable, Sendable {
    case all, current, grouped

    package var title: String {
        switch self {
            case .all: "All Profiles"
            case .current: "This Profile Only"
            case .grouped: "Grouped by Profile"
        }
    }
}
