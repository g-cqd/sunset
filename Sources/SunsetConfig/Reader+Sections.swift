internal import AemiJSONCore
internal import OrderedCollections

/// The sections of the file, one reader each.
extension Reader {
    mutating func readFont(_ object: Object) {
        for (key, value) in object {
            switch key {
                case "family":
                    if let text = string("font.family", value) { configuration.font.family = text.isEmpty ? nil : text }
                case "boldFamily":
                    if let text = string("font.boldFamily", value) {
                        configuration.font.boldFamily = text.isEmpty ? nil : text
                    }
                case "italicFamily":
                    if let text = string("font.italicFamily", value) {
                        configuration.font.italicFamily = text.isEmpty ? nil : text
                    }
                case "boldItalicFamily":
                    if let text = string("font.boldItalicFamily", value) {
                        configuration.font.boldItalicFamily = text.isEmpty ? nil : text
                    }
                case "features":
                    if let text = string("font.features", value) { configuration.font.features = text }
                default: unknown("font.\(key)")
            }
        }
    }

    mutating func readWindow(_ object: Object) {
        for (key, value) in object {
            switch key {
                // Fixed since 2026-11-23 (n115): a file's copies are ignored, and taken out when the file is next saved.
                case "decorations", "trafficLights": break
                case "opacity": readLegacyWindowOpacity(value)
                default: unknown("window.\(key)")
            }
        }
    }

    /// A section whose every key is a plain value its option reads (keyboard, storage, updates, documents, scroll):
    /// anything else in it is not one.
    mutating func readPlain(_ section: String, _ object: Object) {
        for key in object.keys {
            unknown("\(section).\(key)")
        }
    }

    /// `colors`: the foreground, background and cursor are their options' (`SettingCodec`); the palette is read here.
    mutating func readColors(_ object: Object) {
        for (key, value) in object {
            if key == "ansi" { readAnsi(value) } else { unknown("colors.\(key)") }
        }
    }

    mutating func readScrollback(_ object: Object) {
        for (key, value) in object {
            switch key {
                case "lines":
                    if let number = number("scrollback.lines", value, range: 0 ... 10_000_000),
                        number == number.rounded()
                    {
                        configuration.scrollbackLines = Int(number)
                    }
                default: unknown("scrollback.\(key)")
            }
        }
    }

    mutating func readCursor(_ object: Object) {
        for (key, value) in object {
            switch key {
                case "blinkTimeout":
                    if case .null = value {
                        configuration.cursorBlinkTimeout = nil
                    } else if let seconds = number("cursor.blinkTimeout", value, range: 0 ... 86_400) {
                        configuration.cursorBlinkTimeout = seconds == 0 ? nil : seconds
                    }
                default: unknown("cursor.\(key)")
            }
        }
    }
}
