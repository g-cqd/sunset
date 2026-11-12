import SunsetConfig

extension SettingsPane {
    /// The web pane's options (R1).
    static let webEntries: [SettingsEntry] = [
        SettingsEntry(
            id: "web.openLinksInSunset",
            pane: "web",
            title: "Open terminal links in Sunset",
            keywords: ["link", "browser", "cmd-click"]
        ),
        SettingsEntry(
            id: "web.developer",
            pane: "web",
            title: "Page inspector",
            keywords: ["inspect", "developer", "devtools"]
        ),
        SettingsEntry(
            id: "web.tabIcon",
            pane: "web",
            title: "A page's tab picture",
            keywords: ["icon", "globe", "letter", "favicon"]
        ),
        SettingsEntry(
            id: "web.address",
            pane: "web",
            title: "Where the address is",
            keywords: ["address", "url", "bar"]
        ),
        SettingsEntry(
            id: "web.windowBar",
            pane: "web",
            title: "Window bar edge",
            keywords: ["address", "top", "bottom"]
        ),
        SettingsEntry(
            id: "web.engine",
            pane: "web",
            title: "Search engine",
            keywords: ["search", "google", "duckduckgo", "kagi"]
        ),
        SettingsEntry(
            id: "web.suggestions",
            pane: "web",
            title: "Search suggestions",
            keywords: ["suggest", "autocomplete"]
        ),
        SettingsEntry(
            id: "web.httpFallback",
            pane: "web",
            title: "Fall back to http",
            keywords: ["http", "https", "insecure"]
        ),
        SettingsEntry(
            id: "web.engines",
            pane: "web",
            title: "Added search engines",
            keywords: ["engine", "keyword", "custom"]
        )
    ]
}
