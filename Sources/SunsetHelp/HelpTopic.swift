/// One thing help explains: a closed list, so that a gate sees a topic without text.
public enum HelpTopic: String, CaseIterable, Sendable, Identifiable {
    case tabs, splitTabs, pinned, favorites, folders, sidebarField, bottomBar, library, keepAwake, dragAndDrop, renaming
    case tabLayout, spaces
    case features
    case sitePermissions, webNotifications, popUps, pageDialogs, downloads, profiles, privateBrowsing, plainHTTP
    case browserIdentity, blocking, passwords

    public var id: String {
        rawValue
    }

    /// The settings' topic it is about (`SettingsTopic.id`, "web.downloads"): Help is listed under the settings' sections, in
    /// their order, and its page opens those settings.
    public var settingsTopic: String {
        switch self {
            case .features: "general.features"
            case .keepAwake: "general.startup"
            case .spaces, .pinned, .favorites: "general.spaces"
            case .tabs, .splitTabs, .bottomBar, .dragAndDrop, .tabLayout: "tabs.placement"
            case .folders, .renaming: "tabs.labels"
            case .library: "tabs.library"
            case .sidebarField: "web.address"
            case .pageDialogs, .plainHTTP: "web.pages"
            case .downloads: "web.downloads"
            case .sitePermissions, .webNotifications, .popUps, .browserIdentity: "web.websites"
            case .profiles: "web.profiles"
            case .blocking: "web.blocking"
            case .privateBrowsing: "privacy.browsing"
            case .passwords: "privacy.passwords"
        }
    }

    /// The settings' section it is listed under: its topic's.
    public var settingsSection: String {
        Self.section(ofTopic: settingsTopic)
    }

    /// The section a settings' topic is in (design 0009): its id's first part, but for the topics that kept their ids when
    /// they moved to another section.
    public static func section(ofTopic topic: String) -> String {
        switch topic {
            case "general.spaces": return "windows"
            case "general.documents": return "documents"
            case "privacy.programs": return "terminal"
            case "privacy.browsing", "privacy.protection": return "web"
            case "privacy.passwords": return "passwords"
            default:
                let first = String(topic.prefix { $0 != "." })
                return first == "tabs" || first == "window" ? "windows" : first
        }
    }
}
