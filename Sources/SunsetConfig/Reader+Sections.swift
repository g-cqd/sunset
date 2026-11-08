internal import AemiJSONCore
internal import OrderedCollections

/// The sections of the file, one reader each.
extension Reader {
    mutating func readFont(_ object: Object) {
        for (key, value) in object {
            switch key {
                case "family":
                    if let text = string("font.family", value) { configuration.font.family = text.isEmpty ? nil : text }
                case "size":
                    if let number = number("font.size", value, range: 4 ... 200) { configuration.font.size = number }
                case "ligatures":
                    if let flag = bool("font.ligatures", value) { configuration.font.ligatures = flag }
                case "features":
                    if let text = string("font.features", value) { configuration.font.features = text }
                default: unknown("font.\(key)")
            }
        }
    }

    mutating func readWindow(_ object: Object) {
        for (key, value) in object {
            switch key {
                case "decorations":
                    guard case .string(let text) = value, let choice = Configuration.Window.Decorations(rawValue: text)
                    else {
                        let allowed = Configuration.Window.Decorations.allCases.map(\.rawValue).joined(separator: ", ")
                        issue("window.decorations", "expected one of \(allowed)")
                        continue
                    }
                    configuration.window.decorations = choice
                case "trafficLights":
                    section("window.trafficLights", value) { reader, lights in reader.readTrafficLights(lights) }
                case "padding":
                    if let points = number("window.padding", value, range: 0 ... 32) {
                        configuration.window.padding = points
                    }
                case "material":
                    if let choice = choice("window.material", value, as: Configuration.Material.self) {
                        configuration.window.material = choice
                    }
                case "opacity":
                    if let factor = number("window.opacity", value, range: 0 ... 1) {
                        configuration.window.opacity = factor
                    }
                case "blur":
                    if let radius = number("window.blur", value, range: 0 ... 100) {
                        configuration.window.blur = radius
                    }
                case "dragStrip":
                    if let height = number("window.dragStrip", value, range: 0 ... 64) {
                        configuration.window.dragStrip = height
                    }
                default: unknown("window.\(key)")
            }
        }
    }

    mutating func readKeyboard(_ object: Object) {
        for (key, value) in object {
            switch key {
                case "optionAsMeta":
                    if let flag = bool("keyboard.optionAsMeta", value) { configuration.keyboard.optionAsMeta = flag }
                default: unknown("keyboard.\(key)")
            }
        }
    }

    mutating func readScroll(_ object: Object) {
        for (key, value) in object {
            switch key {
                case "trackpad":
                    if let factor = number("scroll.trackpad", value, range: 0.05 ... 20) {
                        configuration.scroll.trackpad = factor
                    }
                case "wheel":
                    if let factor = number("scroll.wheel", value, range: 0.05 ... 50) {
                        configuration.scroll.wheel = factor
                    }
                case "inertia":
                    if let seconds = number("scroll.inertia", value, range: 0 ... 2) {
                        configuration.scroll.inertia = seconds
                    }
                default: unknown("scroll.\(key)")
            }
        }
    }

    mutating func readTrafficLights(_ object: Object) {
        for (key, value) in object {
            switch key {
                case "x":
                    if let x = number("window.trafficLights.x", value, range: 0 ... 400) {
                        configuration.window.trafficLightsX = x
                    }
                case "y":
                    if let y = number("window.trafficLights.y", value, range: 0 ... 400) {
                        configuration.window.trafficLightsY = y
                    }
                default: unknown("window.trafficLights.\(key)")
            }
        }
    }

    mutating func readColors(_ object: Object) {
        for (key, value) in object {
            let path = "colors.\(key)"
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

    mutating func readRenderer(_ value: JSONValue) {
        guard case .string(let text) = value, let choice = Configuration.Renderer(rawValue: text) else {
            issue(
                "renderer",
                "expected one of \(Configuration.Renderer.allCases.map(\.rawValue).joined(separator: ", "))"
            )
            return
        }
        configuration.renderer = choice
    }
}
