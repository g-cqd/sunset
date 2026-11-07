import SunsetConfig

/// The panes of the Settings window, in the order of its sidebar.
enum SettingsPane: String, CaseIterable, Identifiable {
    case font, colors, window, scrolling, terminal, keyboard, file

    var id: String { rawValue }

    var title: String {
        switch self {
            case .font: "Font"
            case .colors: "Colors"
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
                    entry("colors.cursor", "Cursor", ["caret", "color", "colour"])
                ]
            case .window:
                return [
                    entry("window.titlebar", "Title bar", ["decorations", "chrome", "frame", "native"]),
                    entry("window.dragStrip", "Drag strip", ["move", "drag", "top"]),
                    entry(
                        "window.lightsX",
                        "Traffic lights, from the left",
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
                    entry("scroll.history", "History", ["scrollback", "lines", "buffer", "memory"])
                ]
            case .terminal:
                return [
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
}
