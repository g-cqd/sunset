internal import AemiJSONCore
internal import OrderedCollections

/// The sections of the file, one reader each.
extension Reader {
    mutating func readFont(_ object: Object) {
        for (key, value) in object {
            switch key {
                case "family":
                    if let text = string("font.family", value) { configuration.font.family = text.isEmpty ? nil : text }
                case "features":
                    if let text = string("font.features", value) { configuration.font.features = text }
                default: unknown("font.\(key)")
            }
        }
    }

    mutating func readWindow(_ object: Object) {
        for (key, value) in object {
            switch key {
                case "trafficLights":
                    section("window.trafficLights", value) { reader, lights in reader.readTrafficLights(lights) }
                case "opacity": readLegacyWindowOpacity(value)
                default: unknown("window.\(key)")
            }
        }
    }

    mutating func readKeyboard(_ object: Object) {
        // Every key is a plain value its option reads; anything else is not one.
        for key in object.keys {
            unknown("keyboard.\(key)")
        }
    }

    mutating func readStorage(_ object: Object) {
        // Every key is a plain value its option reads; anything else is not one.
        for key in object.keys {
            unknown("storage.\(key)")
        }
    }

    mutating func readDocuments(_ object: Object) {
        // Every key is a plain value its option reads; anything else is not one.
        for key in object.keys {
            unknown("documents.\(key)")
        }
    }

    mutating func readScroll(_ object: Object) {
        // Every key is a plain value its option reads; anything else is not one.
        for key in object.keys {
            unknown("scroll.\(key)")
        }
    }

    mutating func readTrafficLights(_ object: Object) {
        // Every key is a plain value its option reads; anything else is not one.
        for key in object.keys {
            unknown("window.trafficLights.\(key)")
        }
    }

    mutating func readColors(_ object: Object) {
        for (key, value) in object {
            let path = "colors.\(key)"
            if key == "ansi" {
                readAnsi(value)
                continue
            }
            guard ["foreground", "background", "cursor"].contains(key) else {
                unknown(path)
                continue
            }
            // null means "not set": the terminal's own colour.
            let bytes: [UInt8]?
            if case .null = value {
                bytes = nil
            } else if let read = color(path, value) {
                bytes = read
            } else {
                continue
            }
            switch key {
                case "foreground": configuration.colors.foreground = bytes
                case "background": configuration.colors.background = bytes
                default: configuration.colors.cursor = bytes
            }
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
