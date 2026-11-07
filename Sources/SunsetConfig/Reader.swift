internal import AemiJSONCore
internal import OrderedCollections

/// Walks the parsed object once, key by key, against the schema.
struct Reader {
    var configuration = Configuration()
    var issues: [ConfigurationIssue] = []

    private typealias Object = OrderedDictionary<String, JSONValue>

    mutating func read(_ root: OrderedDictionary<String, JSONValue>) {
        for (key, value) in root {
            switch key {
                case "font": section("font", value) { reader, object in reader.readFont(object) }
                case "colors": section("colors", value) { reader, object in reader.readColors(object) }
                case "window": section("window", value) { reader, object in reader.readWindow(object) }
                case "scrollback": section("scrollback", value) { reader, object in reader.readScrollback(object) }
                case "cursor": section("cursor", value) { reader, object in reader.readCursor(object) }
                case "renderer": readRenderer(value)
                default: unknown(key)
            }
        }
    }

    // MARK: Sections

    private mutating func section(_ path: String, _ value: JSONValue, _ body: (inout Reader, Object) -> Void) {
        guard case .object(let object) = value else {
            issue(path, "expected an object")
            return
        }
        body(&self, object)
    }

    private mutating func readFont(_ object: Object) {
        for (key, value) in object {
            switch key {
                case "family":
                    if let text = string("font.family", value) { configuration.font.family = text.isEmpty ? nil : text }
                case "size":
                    if let number = number("font.size", value, range: 4 ... 200) { configuration.font.size = number }
                case "ligatures":
                    if let flag = bool("font.ligatures", value) { configuration.font.ligatures = flag }
                default: unknown("font.\(key)")
            }
        }
    }

    private mutating func readWindow(_ object: Object) {
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
                case "dragStrip":
                    if let height = number("window.dragStrip", value, range: 0 ... 64) {
                        configuration.window.dragStrip = height
                    }
                default: unknown("window.\(key)")
            }
        }
    }

    private mutating func readTrafficLights(_ object: Object) {
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

    private mutating func readColors(_ object: Object) {
        for (key, value) in object {
            switch key {
                case "foreground":
                    configuration.colors.foreground =
                        color("colors.foreground", value) ?? configuration.colors.foreground
                case "background":
                    configuration.colors.background =
                        color("colors.background", value) ?? configuration.colors.background
                case "cursor":
                    configuration.colors.cursor = color("colors.cursor", value) ?? configuration.colors.cursor
                default: unknown("colors.\(key)")
            }
        }
    }

    private mutating func readScrollback(_ object: Object) {
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

    private mutating func readCursor(_ object: Object) {
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

    private mutating func readRenderer(_ value: JSONValue) {
        guard case .string(let text) = value, let choice = Configuration.Renderer(rawValue: text) else {
            issue(
                "renderer",
                "expected one of \(Configuration.Renderer.allCases.map(\.rawValue).joined(separator: ", "))"
            )
            return
        }
        configuration.renderer = choice
    }

    // MARK: Values

    private mutating func issue(_ path: String, _ message: String) {
        issues.append(ConfigurationIssue(path: path, message: message))
    }

    private mutating func unknown(_ path: String) { issue(path, "unknown key") }

    private mutating func string(_ path: String, _ value: JSONValue) -> String? {
        guard case .string(let text) = value else {
            issue(path, "expected a string")
            return nil
        }
        return text
    }

    private mutating func bool(_ path: String, _ value: JSONValue) -> Bool? {
        guard case .bool(let flag) = value else {
            issue(path, "expected true or false")
            return nil
        }
        return flag
    }

    private mutating func number(_ path: String, _ value: JSONValue, range: ClosedRange<Double>) -> Double? {
        let number: Double
        switch value {
            case .int(let integer): number = Double(integer)
            case .number(let double): number = double
            default:
                issue(path, "expected a number")
                return nil
        }
        guard range.contains(number) else {
            issue(path, "expected a number from \(format(range.lowerBound)) to \(format(range.upperBound))")
            return nil
        }
        return number
    }

    private func format(_ value: Double) -> String { value == value.rounded() ? String(Int(value)) : String(value) }

    /// `#rrggbb`.
    private mutating func color(_ path: String, _ value: JSONValue) -> [UInt8]? {
        guard case .string(let text) = value, text.utf8.count == 7, text.hasPrefix("#") else {
            issue(path, "expected a colour written #rrggbb")
            return nil
        }
        var bytes: [UInt8] = []
        let digits = Array(text.utf8.dropFirst())
        for index in stride(from: 0, to: 6, by: 2) {
            guard let high = hexValue(digits[index]), let low = hexValue(digits[index + 1]) else {
                issue(path, "expected a colour written #rrggbb")
                return nil
            }
            bytes.append(high << 4 | low)
        }
        return bytes
    }

    private func hexValue(_ digit: UInt8) -> UInt8? {
        switch digit {
            case 0x30 ... 0x39: digit - 0x30
            case 0x41 ... 0x46: digit - 0x41 + 10
            case 0x61 ... 0x66: digit - 0x61 + 10
            default: nil
        }
    }
}
