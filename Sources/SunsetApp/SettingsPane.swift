import SunsetConfig

/// The panes of the Settings window, in the order of its sidebar.
enum SettingsPane: String, CaseIterable, Identifiable {
    case font, colors, appearance, window, sidebar, layout, tabs, scrolling, terminal, web, keyboard, file

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
            case .web: "Web"
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
            case .web: "globe"
            case .keyboard: "keyboard"
            case .file: "doc.text"
        }
    }

    /// The options of the pane, in the order they are shown (`SettingsOption`, where each is declared once).
    var options: [SettingsOption] { SettingsOption.all.filter { $0.pane == rawValue } }
}
