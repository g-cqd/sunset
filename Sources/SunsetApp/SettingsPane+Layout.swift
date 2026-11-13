import SunsetConfig

extension SettingsPane {
    /// Every metric of `layout.*`: the numbers come from `Configuration.Layout.fields`, so a new one shows up here without a line of its own.
    static func layoutEntries(_ pane: String) -> [SettingsEntry] {
        let numbers = Configuration.Layout.fields.map {
            entry(
                pane,
                "layout.\($0.key)",
                $0.title,
                $0.keywords + ["layout", "spacing", "padding", "margin", "radius"]
            )
        }
        return numbers + [
            entry(
                pane,
                "layout.terminalRadius",
                "Terminal card corner radius",
                ["rounding", "card", "layout", "window"]
            ),
            entry(
                pane,
                "layout.panelRadius",
                "Floating sidebar corner radius",
                ["rounding", "panel", "layout", "window"]
            )
        ]
    }

    static func tabEntries(_ pane: String) -> [SettingsEntry] {
        [
            entry(pane, "tabs.mode", "Tabs", ["native", "internal", "built-in", "none", "windows"]),
            entry(pane, "tabs.restore", "Restore tabs at launch", ["session", "reopen", "quit", "windows"]),
            entry(
                pane,
                "tabs.confirmClose",
                "Confirm closing a tab with a running command",
                ["close", "warn", "running", "red"]
            ),
            entry(pane, "tabs.askBeforeQuit", "Ask before quitting", ["quit", "confirm", "running", "lost", "form"]),
            entry(
                pane,
                "tabs.keepRunningForFavorites",
                "Keep running while a favourite is open",
                ["quit", "last window", "favorites", "background", "dock"]
            ),
            entry(pane, "tabs.position", "Built-in bar position", ["top", "bottom", "internal"]),
            entry(pane, "tabs.icon", "Show the folder or command icon", ["tab", "glyph", "letter", "picture"]),
            entry(pane, "tabs.title", "Show the title", ["tab", "name"]),
            entry(pane, "tabs.directory", "Show the working directory", ["tab", "folder", "path", "osc 7"]),
            entry(pane, "tabs.monospacedDirectory", "Second line in monospace", ["tab", "directory", "font", "mono"]),
            entry(pane, "tabs.progress", "Show progress", ["tab", "bar", "osc 9", "download"])
        ]
    }
}
