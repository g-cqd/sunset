import SunsetConfig

/// The panes of the Settings window, in the order of its sidebar.
enum SettingsPane: String, CaseIterable, Identifiable {
    case font, colors, appearance, window, sidebar, layout, tabs, scrolling, terminal, keyboard, file

    var id: String { rawValue }

    var title: String {
        switch self {
            case .font: "Font"
            case .colors: "Colors"
            case .appearance: "Appearance"
            case .sidebar: "Sidebar"
            case .layout: "Layout"
            case .tabs: "Tabs"
            case .window: "Window"
            case .scrolling: "Scrolling"
            case .terminal: "Terminal"
            case .keyboard: "Keyboard"
            case .file: "Configuration file"
        }
    }

    /// An SF Symbol.
    var symbol: String {
        switch self {
            case .font: "textformat"
            case .colors: "paintpalette"
            case .appearance: "sparkles"
            case .sidebar: "sidebar.left"
            case .layout: "ruler"
            case .tabs: "rectangle.stack"
            case .window: "macwindow"
            case .scrolling: "arrow.up.and.down.text.horizontal"
            case .terminal: "terminal"
            case .keyboard: "keyboard"
            case .file: "doc.text"
        }
    }

    /// The options of the pane, in the order they are shown, with the words people look them up by.
    var entries: [SettingsEntry] {
        func entry(_ id: String, _ title: String, _ keywords: [String]) -> SettingsEntry {
            SettingsEntry(id: id, pane: rawValue, title: title, keywords: keywords)
        }
        switch self {
            case .font:
                return [
                    entry("font.family", "Family", ["font", "typeface", "name", "menlo", "jetbrains"]),
                    entry("font.size", "Size", ["font", "points", "zoom", "bigger", "smaller"]),
                    entry("font.ligatures", "Ligatures", ["font", "calt", "liga", "arrows"]),
                    entry("font.features", "Features", ["font", "opentype", "zero", "ss01", "stylistic"])
                ]
            case .colors:
                return [
                    entry("colors.foreground", "Foreground", ["text", "color", "colour", "theme"]),
                    entry("colors.background", "Background", ["color", "colour", "theme"]),
                    entry("colors.cursor", "Cursor", ["caret", "color", "colour"]),
                    entry(
                        "colors.ansi",
                        "ANSI colors",
                        ["palette", "16", "red", "green", "blue", "terminal colors", "kitty"]
                    )
                ]
            case .appearance: return Self.appearanceEntries(rawValue)
            case .sidebar: return Self.sidebarEntries(rawValue)
            case .layout: return Self.layoutEntries(rawValue)
            case .tabs: return Self.tabEntries(rawValue)
            case .window:
                return [
                    entry("window.titlebar", "Title bar", ["decorations", "chrome", "frame", "native"]),
                    entry("window.dragStrip", "Drag strip", ["move", "drag", "top"]),
                    entry("window.lightsSide", "Traffic lights, side", ["close", "mirror", "left", "right", "buttons"]),
                    entry(
                        "window.lightsX",
                        "Traffic lights, from their edge",
                        ["close", "minimize", "zoom", "buttons", "position"]
                    ),
                    entry(
                        "window.lightsY",
                        "Traffic lights, from the top",
                        ["close", "minimize", "zoom", "buttons", "position"]
                    )
                ]
            case .scrolling:
                return [
                    entry("scroll.trackpad", "Trackpad", ["sensitivity", "speed", "touch", "finger", "scroll"]),
                    entry("scroll.wheel", "Wheel", ["sensitivity", "speed", "mouse", "notch", "scroll"]),
                    entry(
                        "scroll.inertia",
                        "Wheel inertia",
                        ["glide", "momentum", "smooth", "mouse", "deceleration", "scroll"]
                    ),
                    entry("scroll.history", "History", ["scrollback", "lines", "buffer", "memory"])
                ]
            case .terminal:
                return [
                    entry(
                        "terminal.opacity",
                        "Background opacity",
                        ["transparent", "alpha", "see through", "screen", "translucent"]
                    ),
                    entry("terminal.blinkForever", "Cursor blinks for ever", ["blink", "caret", "idle"]),
                    entry("terminal.blinkTimeout", "Stop blinking after", ["blink", "caret", "idle", "seconds"]),
                    entry("terminal.renderer", "Renderer", ["gpu", "cpu", "metal", "auto", "graphics"])
                ]
            case .keyboard:
                return [entry("keyboard.meta", "Option sends Escape", ["meta", "alt", "option", "emacs"])]
            case .file:
                return [
                    entry(
                        "file.location",
                        "Location",
                        ["path", "json", "config", "reveal", "editor", "errors", "problems"]
                    )
                ]
        }
    }

    static var allEntries: [SettingsEntry] { allCases.flatMap(\.entries) }

    private static func entry(_ pane: String, _ id: String, _ title: String, _ keywords: [String]) -> SettingsEntry {
        SettingsEntry(id: id, pane: pane, title: title, keywords: keywords)
    }

    private static func appearanceEntries(_ pane: String) -> [SettingsEntry] {
        [
            entry(pane, "theme.name", "Theme", ["colors", "scheme", "file", "themes", "nord", "dark", "light"]),
            entry(
                pane,
                "window.material",
                "Window background",
                ["material", "glass", "transparent", "opaque", "blur", "vibrancy"]
            ),
            entry(pane, "window.blur", "Window blur", ["radius", "frosted", "background"]),
            entry(pane, "window.padding", "Padding", ["margin", "space", "edge", "border"]),
            entry(pane, "appearance.scheme", "Color scheme", ["dark", "light", "system", "appearance", "mode", "lock"]),
            entry(pane, "appearance.glass", "Glass style", ["liquid glass", "regular", "clear"]),
            entry(pane, "appearance.tint", "Tint", ["colour", "color", "overlay", "glass"]),
            entry(pane, "appearance.tintAlpha", "Tint strength", ["alpha", "opacity", "overlay"])
        ]
    }

    private static func sidebarEntries(_ pane: String) -> [SettingsEntry] {
        [
            entry(pane, "sidebar.enabled", "Show the sidebar", ["tabs", "vertical", "list"]),
            entry(pane, "sidebar.side", "Side", ["left", "right", "edge", "mirror"]),
            entry(pane, "sidebar.width", "Width", ["size", "wide"]),
            entry(pane, "sidebar.padding", "Space around the terminal", ["padding", "margin", "gap"])
        ]
    }

    /// Every metric of `layout.*`: the numbers come from `Configuration.Layout.fields`, so a new one shows up here without a line of its own.
    private static func layoutEntries(_ pane: String) -> [SettingsEntry] {
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

    private static func tabEntries(_ pane: String) -> [SettingsEntry] {
        [
            entry(pane, "tabs.mode", "Tabs", ["native", "internal", "built-in", "none", "windows"]),
            entry(pane, "tabs.restore", "Restore tabs at launch", ["session", "reopen", "quit", "windows"]),
            entry(pane, "tabs.position", "Built-in bar position", ["top", "bottom", "internal"]),
            entry(pane, "tabs.icon", "Show the folder or command icon", ["tab", "glyph", "letter", "picture"]),
            entry(pane, "tabs.title", "Show the title", ["tab", "name"]),
            entry(pane, "tabs.directory", "Show the working directory", ["tab", "folder", "path", "osc 7"]),
            entry(pane, "tabs.progress", "Show progress", ["tab", "bar", "osc 9", "download"])
        ]
    }
}
