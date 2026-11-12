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
            id: "web.zoomScope",
            pane: "web",
            title: "Page zoom applies to",
            keywords: ["zoom", "site", "scale"]
        ),
        SettingsEntry(id: "web.textOnlyZoom", pane: "web", title: "Zoom text only", keywords: ["zoom", "text", "font"]),
        SettingsEntry(
            id: "web.historyKeep",
            pane: "web",
            title: "Keep history for",
            keywords: ["history", "remove", "days"]
        ),
        SettingsEntry(
            id: "web.clearHistoryOnQuit",
            pane: "web",
            title: "Clear history when Sunset quits",
            keywords: ["history", "quit", "privacy"]
        ),
        SettingsEntry(
            id: "web.clearWebsiteDataOnQuit",
            pane: "web",
            title: "Clear website data when Sunset quits",
            keywords: ["cookies", "cache", "quit", "privacy"]
        ),
        SettingsEntry(
            id: "web.privateSuggestions",
            pane: "web",
            title: "Suggestions in private pages",
            keywords: ["private", "incognito", "suggest"]
        ),
        SettingsEntry(
            id: "web.privateWindowShares",
            pane: "web",
            title: "Private windows share their data",
            keywords: ["private", "incognito", "store", "cookies"]
        ),
        SettingsEntry(
            id: "web.permissions",
            pane: "web",
            title: "Websites",
            keywords: ["camera", "microphone", "location", "notifications", "popup", "permission", "screen"]
        ),
        SettingsEntry(
            id: "web.engines",
            pane: "web",
            title: "Added search engines",
            keywords: ["engine", "keyword", "custom"]
        )
    ]
}
