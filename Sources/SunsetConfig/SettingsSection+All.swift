/// The sections of Settings, in the sidebar's order, each with its topics in theirs. An option is declared in
/// `SettingsOption+*.swift`, in the list of its topic; a number of the layout is named here, beside the thing it measures.
extension SettingsSection {
    public static let all: [Self] = [general, appearance, window, tabs, terminal, web, privacy]

    static let general = Self(
        id: "general",
        title: "General",
        symbol: "gearshape",
        topics: [
            SettingsTopic("general.startup", "Startup, closing and quitting", SettingsOption.startup),
            SettingsTopic("general.documents", "Documents", SettingsOption.documents),
            SettingsTopic("general.file", "Configuration file", SettingsOption.configurationFile)
        ]
    )

    static let appearance = Self(
        id: "appearance",
        title: "Appearance",
        symbol: "paintpalette",
        topics: [
            SettingsTopic("appearance.theme", "Theme and colours", SettingsOption.theme),
            SettingsTopic("appearance.tint", "Accent and tint", SettingsOption.tint),
            SettingsTopic("appearance.materials", "Materials", SettingsOption.materials)
        ]
    )

    static let window = Self(
        id: "window",
        title: "Window",
        symbol: "macwindow",
        topics: [
            SettingsTopic(
                "window.titleBar",
                "Title bar and buttons",
                SettingsOption.titleBar + SettingsOption.layout("lightsInset", "lightsGap", "floatingLightsExtra")
            ),
            SettingsTopic(
                "window.spacing",
                "Spacing and corners",
                SettingsOption.spacing
                    + SettingsOption.layout(
                        "innerCornerRadius",
                        "paneGap",
                        "resizeHandleWidth",
                        "hairlineWidth",
                        "hairlineOpacity",
                        "animation"
                    )
            )
        ]
    )

    static let tabs = Self(
        id: "tabs",
        title: "Tabs and sidebar",
        symbol: "sidebar.left",
        topics: [
            SettingsTopic("tabs.placement", "Placement", SettingsOption.placement),
            SettingsTopic(
                "tabs.floating",
                "Floating sidebar",
                SettingsOption.layout("hideDelay", "revealStripWidth") + SettingsOption.floatingRadius
                    + SettingsOption.layout(
                        "sidebarButtonSize",
                        "floatingTabSpacing",
                        "floatingTabSideInset",
                        "floatingTabPaddingLeading",
                        "floatingTabPaddingTrailing",
                        "floatingTabPaddingVertical",
                        "floatingTabRadius",
                        "floatingCloseButtonSize",
                        "floatingCloseButtonRadius"
                    )
            ),
            SettingsTopic("tabs.labels", "Tab labels", SettingsOption.labels),
            SettingsTopic(
                "tabs.metrics",
                "Tab metrics",
                SettingsOption.layout(
                    "tabSpacing",
                    "tabSideInset",
                    "tabPaddingLeading",
                    "tabPaddingTrailing",
                    "tabPaddingVertical",
                    "tabRadius",
                    "closeButtonSize",
                    "closeButtonRadius",
                    "sidebarButtonRadius"
                )
            ),
            SettingsTopic("tabs.library", "Library and documents", SettingsOption.library)
        ]
    )

    static let terminal = Self(
        id: "terminal",
        title: "Terminal",
        symbol: "terminal",
        topics: [
            SettingsTopic("terminal.text", "Text", SettingsOption.text),
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
            SettingsTopic("privacy.kept", "What is kept", SettingsOption.kept),
            SettingsTopic("privacy.key", "Key and recovery", SettingsOption.keyAndRecovery),
            SettingsTopic("privacy.export", "Export", SettingsOption.export)
        ]
    )
}
