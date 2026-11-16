/// What a sidebar shows (roadmap 0031, 0032): the tabs, one of the lists of the Library and of the panel opposite the tabs, or
/// the sections and topics of the settings (the gear at the foot of the Library's rail).
package enum SidebarSection: String, Sendable, CaseIterable {
    case tabs, documents, history, downloads, settings

    /// The sections of the panel opposite the tabs, in the order of its switch.
    package static let panel: [Self] = [.history, .documents, .downloads]
    /// The glyphs of the Library's rail, from its top: Tabs goes back to the tabs.
    package static let rail: [Self] = [.tabs, .documents, .history, .downloads]

    package var title: String {
        switch self {
            case .tabs: "Tabs"
            case .documents: "Documents"
            case .history: "History"
            case .downloads: "Downloads"
            case .settings: "Settings"
        }
    }

    /// Whether the section has a search field while it lists `count` things: with nothing in it there is nothing to search
    /// (the owner, 2026-11-15). The settings are always there to search; the tabs have no field of their own.
    package func isSearched(count: Int) -> Bool {
        switch self {
            case .settings: true
            case .tabs: false
            case .documents, .history, .downloads: count > 0
        }
    }

    /// An SF Symbol.
    package var symbol: String {
        switch self {
            case .tabs: "rectangle.stack"
            case .documents: "doc.text"
            case .history: "clock"
            case .downloads: "arrow.down.circle"
            case .settings: "gearshape"
        }
    }
}
