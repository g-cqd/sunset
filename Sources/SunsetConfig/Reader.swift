internal import AemiJSONCore
internal import OrderedCollections

/// Walks the parsed object once, key by key, against the schema.
struct Reader {
    var configuration: Configuration
    var issues: [ConfigurationIssue] = []
    let scope: ConfigurationParser.Scope
    /// `terminal.opacity` was given: the old `window.opacity` no longer applies after it.
    var terminalOpacitySet = false

    /// The top-level keys a theme may set: everything visual.
    private static let themeKeys: Set<String> = [
        "font", "colors", "window", "sidebar", "appearance", "layout", "terminal"
    ]

    init(configuration: Configuration = Configuration(), scope: ConfigurationParser.Scope = .file) {
        self.configuration = configuration
        self.scope = scope
    }

    typealias Object = OrderedDictionary<String, JSONValue>

    mutating func read(_ root: OrderedDictionary<String, JSONValue>) {
        for (key, value) in root {
            if scope == .theme, !Self.themeKeys.contains(key) {
                issue(key, "not allowed in a theme (a theme sets only what is visual)")
                continue
            }
            switch key {
                case "font": section("font", value) { reader, object in reader.readFont(object) }
                case "colors": section("colors", value) { reader, object in reader.readColors(object) }
                case "window": section("window", value) { reader, object in reader.readWindow(object) }
                case "sidebar": section("sidebar", value) { reader, object in reader.readSidebar(object) }
                case "appearance": section("appearance", value) { reader, object in reader.readAppearance(object) }
                case "terminal": section("terminal", value) { reader, object in reader.readTerminal(object) }
                case "layout": section("layout", value) { reader, object in reader.readLayout(object) }
                case "tabs": section("tabs", value) { reader, object in reader.readTabs(object) }
                case "theme": readTheme(value)
                case "keyboard": section("keyboard", value) { reader, object in reader.readKeyboard(object) }
                case "scroll": section("scroll", value) { reader, object in reader.readScroll(object) }
                case "scrollback": section("scrollback", value) { reader, object in reader.readScrollback(object) }
                case "cursor": section("cursor", value) { reader, object in reader.readCursor(object) }
                case "renderer": readRenderer(value)
                default: unknown(key)
            }
        }
    }

    // MARK: Sections

    mutating func section(_ path: String, _ value: JSONValue, _ body: (inout Reader, Object) -> Void) {
        guard case .object(let object) = value else {
            issue(path, "expected an object")
            return
        }
        body(&self, object)
    }

    // MARK: Values

    mutating func issue(_ path: String, _ message: String) {
        issues.append(ConfigurationIssue(path: path, message: message))
    }

    mutating func unknown(_ path: String) { issue(path, "unknown key") }

    mutating func string(_ path: String, _ value: JSONValue) -> String? {
        guard case .string(let text) = value else {
            issue(path, "expected a string")
            return nil
        }
        return text
    }

    mutating func bool(_ path: String, _ value: JSONValue) -> Bool? {
        guard case .bool(let flag) = value else {
            issue(path, "expected true or false")
            return nil
        }
        return flag
    }

    mutating func number(_ path: String, _ value: JSONValue, range: ClosedRange<Double>) -> Double? {
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

    func format(_ value: Double) -> String { value == value.rounded() ? String(Int(value)) : String(value) }

    /// `#rrggbb`.
    mutating func color(_ path: String, _ value: JSONValue) -> [UInt8]? {
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

    func hexValue(_ digit: UInt8) -> UInt8? {
        switch digit {
            case 0x30 ... 0x39: digit - 0x30
            case 0x41 ... 0x46: digit - 0x41 + 10
            case 0x61 ... 0x66: digit - 0x61 + 10
            default: nil
        }
    }
}
