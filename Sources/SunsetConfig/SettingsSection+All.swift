/// The sections of Settings, in the sidebar's order, each with its topics in theirs. An option is declared in
/// `SettingsOption+*.swift`, in the list of its topic; a number of the layout is named here, beside the thing it measures.
extension SettingsSection {
    public static let all: [Self] = [general, appearance, terminal, web, privacy]

    static let general = Self(
        id: "general",
        title: "General",
        symbol: "gearshape",
        topics: [
            SettingsTopic("general.features", "Features", SettingsOption.features),
            SettingsTopic("general.startup", "Startup, closing and quitting", SettingsOption.startup),
            SettingsTopic("general.documents", "Documents", SettingsOption.documents),
            SettingsTopic("general.spaces", "Spaces", SettingsOption.spaces),
            SettingsTopic("general.keys", "Keyboard shortcuts", SettingsOption.keys),
            SettingsTopic("general.updates", "Updates", SettingsOption.updates),
            SettingsTopic("general.file", "Configuration file", SettingsOption.configurationFile)
        ]
    )

    /// How the window looks and how its tabs are laid out, together (n119: Appearance, Window and Tabs and sidebar spoke of
    /// the same things in three places). The topics keep their ids: Help links to them.
    static let appearance = Self(
        id: "appearance",
        title: "Appearance and layout",
        symbol: "paintpalette",
        topics: [
            SettingsTopic("appearance.theme", "Theme and colors", SettingsOption.theme),
            SettingsTopic("appearance.tint", "Accent and tint", SettingsOption.tint),
            SettingsTopic("appearance.materials", "Materials", SettingsOption.materials),
            SettingsTopic("window.titleBar", "Window", SettingsOption.window),
            SettingsTopic("tabs.placement", "Tabs and sidebar", SettingsOption.placement),
            SettingsTopic("tabs.labels", "Tab labels", SettingsOption.labels),
            SettingsTopic("tabs.library", "Library and documents", SettingsOption.library),
            SettingsTopic("tabs.new", "New tabs", SettingsOption.newTabs),
            SettingsTopic(
                "tabs.floating",
                "Floating sidebar",
                SettingsOption.layout("hideDelay", "revealStripWidth")
            )
        ]
    )

    static let terminal = Self(
        id: "terminal",
        title: "Terminal",
        symbol: "terminal",
        topics: [
            SettingsTopic("terminal.text", "Text", SettingsOption.text + SettingsOption.spacing),
            SettingsTopic("terminal.cursor", "Cursor", SettingsOption.cursor),
            SettingsTopic("terminal.scrolling", "Scrolling and history", SettingsOption.scrolling),
            SettingsTopic("terminal.shell", "Shell and programs", SettingsOption.shell),
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
            SettingsTopic("web.memory", "Memory", SettingsOption.memory),
            SettingsTopic("web.blocking", "Blocking", SettingsOption.blocking),
            SettingsTopic("web.extensions", "Extensions", SettingsOption.extensions),
            SettingsTopic("web.proxy", "Proxy", SettingsOption.proxy),
            SettingsTopic("web.advanced", "Advanced", SettingsOption.webAdvanced)
        ]
    )

    static let privacy = Self(
        id: "privacy",
        title: "Privacy and security",
        symbol: "hand.raised",
        topics: [
            SettingsTopic("privacy.programs", "Programs in a terminal", SettingsOption.programs),
            SettingsTopic("privacy.browsing", "Browsing", SettingsOption.browsing),
            SettingsTopic("privacy.protection", "Protection on the web", SettingsOption.webProtection),
            SettingsTopic("privacy.kept", "What is kept", SettingsOption.kept),
            SettingsTopic("privacy.key", "Key and recovery", SettingsOption.keyAndRecovery),
            SettingsTopic("privacy.passwords", "Passwords", SettingsOption.passwords),
            SettingsTopic("privacy.export", "Export", SettingsOption.export)
        ]
    )
}
