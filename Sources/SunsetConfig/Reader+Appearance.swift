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
                case "padding":
                    if let points = number(path, value, range: 0 ... 16) { configuration.sidebar.padding = points }
                case "enabled": if let flag = bool(path, value) { configuration.sidebar.enabled = flag }
                case "autoHide": if let flag = bool(path, value) { configuration.sidebar.autoHide = flag }
                case "width":
                    if let points = number(path, value, range: 120 ... 480) { configuration.sidebar.width = points }
                // A Documents heading among the tabs, for a day (2026-11-15): the key is read and does nothing, so that a file
                // written that day does not complain.
                case "documents": break
                // Removed: the sidebar takes the window's material and blur. Files written before still have them; they are ignored without a warning.
                case "material", "blur": break
                default: unknown(path)
            }
        }
    }

    mutating func readAppearance(_ object: Object) {
        for (key, value) in object {
            switch key {
                case "tint": section("appearance.tint", value) { reader, tint in reader.readTint(tint) }
                default: unknown("appearance.\(key)")
            }
        }
    }

    /// The tint's keys that are not settings: its light colour and strength from before the tint had a value per scheme,
    /// kept as its light values (`finish`).
    private mutating func readTint(_ object: Object) {
        for (key, value) in object {
            switch key {
                case "light":
                    migrated = true
                    if case .null = value {
                        formerLight[SettingsOption.tintColorKey] = "null"
                    } else if let bytes = color("appearance.tint.light", value) {
                        formerLight[SettingsOption.tintColorKey] = ConfigurationWriter.color(bytes)
                    }
                case "lightAlpha":
                    migrated = true
                    if let alpha = number("appearance.tint.lightAlpha", value, range: 0 ... 1) {
                        formerLight[SettingsOption.tintAlphaKey] = ConfigurationWriter.number(alpha)
                    }
                default: unknown("appearance.tint.\(key)")
            }
        }
    }

    /// The switches of `tabs.*`, by their key.
    static var tabFlags: [String: WritableKeyPath<Configuration.Tabs, Bool>] {
        [
            "restore": \.restore, "confirmClose": \.confirmClose, "keepRunningForFavorites": \.keepRunningForFavorites,
            "closeWithLastWindow": \.closeWithLastWindow, "closeWindowWithLastTab": \.closeWindowWithLastTab,
            "closeGoesBack": \.closeGoesBack, "keepAwakeDisplay": \.keepAwakeDisplay
        ]
    }

    /// The texts of `tabs`.
    static var tabTexts: [String: WritableKeyPath<Configuration.Tabs, String>] {
        ["startAddress": \.startAddress, "startFile": \.startFile, "startProfile": \.startProfile]
    }

    mutating func readTabs(_ object: Object) {
        for (key, value) in object {
            switch key {
                case _ where Self.tabFlags[key] != nil:
                    if let path = Self.tabFlags[key], let flag = bool("tabs.\(key)", value) {
                        configuration.tabs[keyPath: path] = flag
                    }
                case "bar": section("tabs.bar", value) { reader, bar in reader.readTabBar(bar) }
                // What opens with no tab: texts, read as written.
                case _ where Self.tabTexts[key] != nil:
                    if let path = Self.tabTexts[key], let text = string("tabs.\(key)", value) {
                        configuration.tabs[keyPath: path] = text
                    }
                default: unknown("tabs.\(key)")
            }
        }
    }

    private mutating func readTabBar(_ object: Object) {
        // Every key is a plain value its option reads; anything else is not one.
        for key in object.keys {
            unknown("tabs.bar.\(key)")
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
