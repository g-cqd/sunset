internal import AemiJSONCore
internal import OrderedCollections

/// The sections about how the window looks and how its tabs work.
extension Reader {
    /// A string that must be one of the cases of `Type` (by raw value); issues the allowed names otherwise.
    mutating func choice<Type: RawRepresentable & CaseIterable>(_ path: String, _ value: JSONValue, as: Type.Type)
        -> Type?
    where Type.RawValue == String {
        if case .string(let text) = value, let found = Type(rawValue: text) { return found }
        issue(path, "expected one of \(Type.allCases.map(\.rawValue).joined(separator: ", "))")
        return nil
    }

    mutating func readSidebar(_ object: Object) {
        for (key, value) in object {
            let path = "sidebar.\(key)"
            switch key {
                case "enabled": if let flag = bool(path, value) { configuration.sidebar.enabled = flag }
                case "width":
                    if let points = number(path, value, range: 120 ... 480) { configuration.sidebar.width = points }
                case "padding":
                    if let points = number(path, value, range: 0 ... 16) { configuration.sidebar.padding = points }
                case "autoHide": if let flag = bool(path, value) { configuration.sidebar.autoHide = flag }
                case "side":
                    if let side = choice(path, value, as: Configuration.Side.self) { configuration.sidebar.side = side }
                // Removed: the sidebar takes the window's material and blur. Files written before still have them; they are ignored without a warning.
                case "material", "blur": break
                default: unknown(path)
            }
        }
    }

    mutating func readAppearance(_ object: Object) {
        for (key, value) in object {
            switch key {
                case "scheme":
                    if let choice = choice("appearance.scheme", value, as: Configuration.Appearance.Scheme.self) {
                        configuration.appearance.scheme = choice
                    }
                case "glass":
                    if let choice = choice("appearance.glass", value, as: Configuration.Appearance.Glass.self) {
                        configuration.appearance.glass = choice
                    }
                case "tint": section("appearance.tint", value) { reader, tint in reader.readTint(tint) }
                case "accent":
                    if let accent = choice("appearance.accent", value, as: Configuration.Appearance.Accent.self) {
                        configuration.appearance.accent = accent
                    }
                default: unknown("appearance.\(key)")
            }
        }
    }

    private mutating func readTint(_ object: Object) {
        for (key, value) in object {
            switch key {
                case "color":
                    if case .null = value {
                        configuration.appearance.tintColor = nil
                    } else if let bytes = color("appearance.tint.color", value) {
                        configuration.appearance.tintColor = bytes
                    }
                case "alpha":
                    if let alpha = number("appearance.tint.alpha", value, range: 0 ... 1) {
                        configuration.appearance.tintAlpha = alpha
                    }
                default: unknown("appearance.tint.\(key)")
            }
        }
    }

    mutating func readTabs(_ object: Object) {
        for (key, value) in object {
            switch key {
                case "mode":
                    if let choice = choice("tabs.mode", value, as: Configuration.Tabs.Mode.self) {
                        configuration.tabs.mode = choice
                    }
                case "restore": if let flag = bool("tabs.restore", value) { configuration.tabs.restore = flag }
                case "confirmClose":
                    if let flag = bool("tabs.confirmClose", value) { configuration.tabs.confirmClose = flag }
                case "keepRunningForFavorites":
                    if let flag = bool("tabs.keepRunningForFavorites", value) {
                        configuration.tabs.keepRunningForFavorites = flag
                    }
                case "askBeforeQuit":
                    if let ask = choice("tabs.askBeforeQuit", value, as: Configuration.Tabs.QuitAsk.self) {
                        configuration.tabs.askBeforeQuit = ask
                    }
                case "bar": section("tabs.bar", value) { reader, bar in reader.readTabBar(bar) }
                default: unknown("tabs.\(key)")
            }
        }
    }

    private mutating func readTabBar(_ object: Object) {
        for (key, value) in object {
            let path = "tabs.bar.\(key)"
            switch key {
                case "position":
                    if let choice = choice(path, value, as: Configuration.Tabs.Bar.Position.self) {
                        configuration.tabs.bar.position = choice
                    }
                case "icon": if let flag = bool(path, value) { configuration.tabs.bar.showIcon = flag }
                case "title": if let flag = bool(path, value) { configuration.tabs.bar.showTitle = flag }
                case "directory": if let flag = bool(path, value) { configuration.tabs.bar.showDirectory = flag }
                case "monospacedDirectory":
                    if let flag = bool(path, value) { configuration.tabs.bar.monospacedDirectory = flag }
                case "progress": if let flag = bool(path, value) { configuration.tabs.bar.showProgress = flag }
                default: unknown(path)
            }
        }
    }

    mutating func readTheme(_ value: JSONValue) {
        switch value {
            case .null: configuration.theme = nil
            case .string(let name): configuration.theme = name.isEmpty ? nil : name
            default: issue("theme", "expected the name of a theme, or null")
        }
    }
}
