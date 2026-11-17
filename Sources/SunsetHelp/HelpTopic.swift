/// One thing help explains (roadmap 0041 A): a closed list, so that a gate sees a topic without text.
public enum HelpTopic: String, CaseIterable, Sendable, Identifiable {
    case tabs, splitTabs, pinned, favorites, folders, sidebarField, bottomBar, library, keepAwake, dragAndDrop, renaming

    public var id: String { rawValue }

    /// The area it is listed under.
    public var area: HelpArea {
        switch self {
            case .tabs, .splitTabs, .pinned, .favorites, .folders, .sidebarField, .bottomBar, .library, .keepAwake,
                .dragAndDrop, .renaming:
                .sidebar
        }
    }
}
