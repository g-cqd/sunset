/// What a sidebar shows (roadmap 0031): the tabs, or one of the lists of the Library and of the panel opposite the tabs.
package enum SidebarSection: String, Sendable, CaseIterable {
    case tabs, documents, history, downloads

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
        }
    }

    /// An SF Symbol.
    package var symbol: String {
        switch self {
            case .tabs: "rectangle.stack"
            case .documents: "doc.text"
            case .history: "clock"
            case .downloads: "arrow.down.circle"
        }
    }
}
