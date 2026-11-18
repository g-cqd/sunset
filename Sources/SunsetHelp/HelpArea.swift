/// A part of Sunset that help explains (roadmap 0041), in the order the owner gave: the sidebar's controls, then the
/// settings, then the web's permissions. An area is listed in the Help window with its topics.
public enum HelpArea: String, CaseIterable, Sendable {
    case sidebar, general, web

    /// Its name in the Help window.
    public var title: String {
        switch self {
            case .sidebar: "Sidebar"
            case .general: "General"
            case .web: "Websites and privacy"
        }
    }
}
