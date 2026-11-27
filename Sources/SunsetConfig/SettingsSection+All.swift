/// The sections of Settings, in the sidebar's order, each with its topics in theirs. An option is declared in
/// `SettingsOption+*.swift`, in the list of its topic; a number of the layout is named here, beside the thing it measures.
extension SettingsSection {
    /// The app's sections, then one for each feature scope (listed while its scope is on: `sections(for:)`). What a scope
    /// owns is in its section and nowhere else (design 0009).
    public static let all: [Self] = [general, look, windows, privacy, terminal, web, documents, passwords]

    static let general = Self(
        id: "general",
        title: "General",
        symbol: "gearshape",
        topics: [
            SettingsTopic("general.features", "Features", SettingsOption.features),
            SettingsTopic("general.startup", "Startup and quitting", SettingsOption.startup),
            SettingsTopic("general.updates", "Updates", SettingsOption.updates),
            SettingsTopic("general.keys", "Keyboard shortcuts", SettingsOption.keys),
            SettingsTopic("general.control", "Control from outside", SettingsOption.control),
            SettingsTopic("general.file", "Configuration file", SettingsOption.configurationFile)
        ]
    )

    /// What the whole app looks and feels like; a scope's own look (the terminal's colors) is in its scope's section.
    static let look = Self(
        id: "appearance",
        title: "Look and feel",
        symbol: "paintpalette",
        topics: [
            SettingsTopic("appearance.theme", "Appearance", SettingsOption.appearance),
            SettingsTopic("appearance.tint", "Accent and tint", SettingsOption.tint),
            SettingsTopic("appearance.materials", "Materials", SettingsOption.materials),
            SettingsTopic("appearance.feedback", "Feedback", SettingsOption.feedback)
        ]
    )

    /// The windows, their tabs, the sidebar and the Spaces. The topics keep their ids: Help links to them.
    static let windows = Self(
        id: "windows",
        title: "Windows and tabs",
        symbol: "macwindow",
        topics: [
            SettingsTopic("window.titleBar", "Window", SettingsOption.window),
            SettingsTopic("tabs.placement", "Tabs and sidebar", SettingsOption.placement),
            SettingsTopic("tabs.labels", "Tab labels", SettingsOption.labels),
            SettingsTopic("tabs.library", "Previews and Library", SettingsOption.library),
            SettingsTopic("tabs.new", "New tabs", SettingsOption.newTabs),
            SettingsTopic(
                "tabs.floating",
                "Floating sidebar",
                SettingsOption.layout("hideDelay", "revealStripWidth")
            ),
            SettingsTopic("general.spaces", "Spaces", SettingsOption.spaces)
        ]
    )

    /// What Sunset keeps, sealed with its key, of every scope.
    static let privacy = Self(
        id: "privacy",
        title: "Privacy and storage",
        symbol: "hand.raised",
        topics: [
            SettingsTopic("privacy.kept", "What is kept", SettingsOption.kept),
            SettingsTopic("privacy.key", "Key and recovery", SettingsOption.keyAndRecovery),
            SettingsTopic("privacy.export", "Export", SettingsOption.export)
        ]
    )

    static let terminal = Self(
        id: "terminal",
        title: "Terminal",
        symbol: "terminal",
        topics: [
            SettingsTopic("terminal.text", "Text", SettingsOption.text + SettingsOption.spacing),
            SettingsTopic("terminal.colors", "Colors", SettingsOption.terminalColors),
            SettingsTopic("terminal.cursor", "Cursor", SettingsOption.cursor),
            SettingsTopic("terminal.scrolling", "Scrolling and history", SettingsOption.scrolling),
            SettingsTopic("terminal.shell", "Shell", SettingsOption.shell),
            SettingsTopic("privacy.programs", "Programs", SettingsOption.programs),
            SettingsTopic("terminal.advanced", "Advanced", SettingsOption.rendering)
        ]
    )

    static let web = Self(
        id: "web",
        title: "Web",
        symbol: "globe",
        topics: [
            SettingsTopic("web.address", "Address and bars", SettingsOption.addressBars),
            SettingsTopic("web.search", "Search", SettingsOption.search),
            SettingsTopic("web.pages", "Pages", SettingsOption.pages),
            SettingsTopic("web.downloads", "Downloads", SettingsOption.downloads),
            SettingsTopic("web.websites", "Websites", SettingsOption.websites),
            SettingsTopic("web.sites", "Each site", SettingsOption.sites),
            SettingsTopic("web.profiles", "Profiles", SettingsOption.profiles),
            SettingsTopic("privacy.browsing", "History and site data", SettingsOption.browsing),
            SettingsTopic("privacy.protection", "Protection", SettingsOption.webProtection),
            SettingsTopic("web.blocking", "Blocking", SettingsOption.blocking),
            SettingsTopic("web.extensions", "Extensions", SettingsOption.extensions),
            SettingsTopic("web.memory", "Memory", SettingsOption.memory),
            SettingsTopic("web.proxy", "Proxy", SettingsOption.proxy),
            SettingsTopic("web.advanced", "Advanced", SettingsOption.webAdvanced)
        ]
    )

    static let documents = Self(
        id: "documents",
        title: "Documents",
        symbol: "doc.text",
        topics: [
            SettingsTopic("general.documents", "Editing", SettingsOption.documents),
            SettingsTopic("documents.library", "Library", SettingsOption.documentsLibrary)
        ]
    )

    static let passwords = Self(
        id: "passwords",
        title: "Passwords",
        symbol: "key",
        topics: [SettingsTopic("privacy.passwords", "Passwords", SettingsOption.passwords)]
    )
}
