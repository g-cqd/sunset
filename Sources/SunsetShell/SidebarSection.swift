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
