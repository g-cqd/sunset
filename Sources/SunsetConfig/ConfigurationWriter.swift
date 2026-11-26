import SunsetMetrics

/// Writes a configuration as the text of a file: every key, so that the file shows what can be set. Colours not set are written as null, a font with no family
/// as an empty string, a cursor that blinks for ever as null.
public enum ConfigurationWriter {
    /// Every key of the file with its value as a JSON literal, by dotted path.
    public static func literals(for configuration: Configuration) -> [String: String] {
        let font = configuration.font
        let colors = configuration.colors
        var layout: [String: String] = [:]
        layout["colors.ansi"] = "[" + colors.ansi.map { color($0) }.joined(separator: ", ") + "]"
        for field in Configuration.Layout.fields {
            layout["layout.\(field.key)"] = number(configuration.layout[keyPath: field.path])
        }
        layout.merge(extras(configuration)) { $1 }
        // A plain value is written by its option's codec.
        for (key, codec) in SettingCodec.byKey {
            layout[key] = codec.literal(configuration)
        }
        return layout.merging([
            "font.family": string(font.family ?? ""),
            "font.boldFamily": string(font.boldFamily ?? ""),
            "font.italicFamily": string(font.italicFamily ?? ""),
            "font.boldItalicFamily": string(font.boldItalicFamily ?? ""),
            "font.features": string(font.features),
            "colors.foreground": color(colors.foreground),
            "colors.background": color(colors.background),
            "colors.cursor": color(colors.cursor),
            "scrollback.lines": String(configuration.scrollbackLines),
            "cursor.blinkTimeout": configuration.cursorBlinkTimeout.map(number) ?? "null",
            "terminal.directory": string(configuration.terminal.directory),
            "sidebar.padding": number(configuration.sidebar.padding),
            "sidebar.enabled": String(configuration.sidebar.enabled),
            "sidebar.autoHide": String(configuration.sidebar.autoHide),
            "sidebar.width": number(configuration.sidebar.width),
            "appearance.tint.color": color(configuration.appearance.tintColor),
            "layout.terminalRadius": configuration.layout.terminalRadius.map(number) ?? "null",
            "layout.panelRadius": configuration.layout.panelRadius.map(number) ?? "null",
            "theme": configuration.theme.map(string) ?? "null"
        ]) { first, _ in first }
    }

    /// The whole file, in the order of `ConfigurationKeys.all`.
    public static func text(for configuration: Configuration) -> String {
        let values = literals(for: configuration)
        var lines: [String] = ["{"]
        var open: [String] = []
        let keys = ConfigurationKeys.all
        for (index, key) in keys.enumerated() {
            let parts = key.split(separator: ".").map(String.init)
            let sections = Array(parts.dropLast())
            // Close the sections that are no longer open, open the new ones.
            var common = 0
            while common < open.count, common < sections.count, open[common] == sections[common] { common += 1 }
            while open.count > common {
                open.removeLast()
                lines.append(String(repeating: "  ", count: open.count + 1) + "},")
            }
            for name in sections[common...] {
                lines.append(String(repeating: "  ", count: open.count + 1) + string(name) + ": {")
                open.append(name)
            }
            let last = index == keys.count - 1
            lines.append(
                String(repeating: "  ", count: open.count + 1) + string(parts[parts.count - 1]) + ": "
                    + (values[key] ?? "null")
                    + (last ? "" : ",")
            )
        }
        while !open.isEmpty {
            open.removeLast()
            lines.append(String(repeating: "  ", count: open.count + 1) + "}" + (open.isEmpty ? "" : ","))
        }
        lines.append("}")
        return lines.joined(separator: "\n") + "\n"
    }

    static func web(_ web: Configuration.Web) -> [String: String] {
        [
            "web.engine": string(web.engine),
            "web.engines": "[" + web.engines.map(engine).joined(separator: ", ") + "]",
            "web.agent": string(web.agent.rawValue),
            "web.proxy": string(web.proxy),
            "web.blockingLists": "[" + web.blockingLists.map(string).joined(separator: ", ") + "]",
            "web.textOnlyZoom": String(web.textOnlyZoom),
            "web.downloadFolder": string(web.downloadFolder)
        ]
    }

    static func permissions(_ web: Configuration.Web) -> [String: String] {
        Dictionary(
            uniqueKeysWithValues: Configuration.Web.permissionNames.map {
                ("web.permissions.\($0)", string((web.permissions[$0] ?? .ask).rawValue))
            }
        )
    }

    private static func engine(_ engine: Configuration.Web.Engine) -> String {
        var fields = [
            "\"name\": " + string(engine.name), "\"keyword\": " + string(engine.keyword),
            "\"search\": " + string(engine.search)
        ]
        if let suggest = engine.suggest { fields.append("\"suggest\": " + string(suggest)) }
        return "{ " + fields.joined(separator: ", ") + " }"
    }

    static func number(_ value: Double) -> String {
        value == value.rounded() && abs(value) < 1e15 ? String(Int(value)) : String(value)
    }

    static func color(_ bytes: [UInt8]?) -> String {
        guard let bytes, bytes.count == 3 else { return "null" }
        let digits = Array("0123456789abcdef")
        return "\"#" + bytes.map { String([digits[Int($0 >> 4)], digits[Int($0 & 15)]]) }.joined() + "\""
    }

    static func string(_ text: String) -> String {
        var result = "\""
        for scalar in text.unicodeScalars {
            switch scalar {
                case "\"": result += "\\\""
                case "\\": result += "\\\\"
                case "\n": result += "\\n"
                case "\t": result += "\\t"
                case "\r": result += "\\r"
                default:
                    if scalar.value < 0x20 {
                        let hex = String(scalar.value, radix: 16)
                        result += "\\u" + String(repeating: "0", count: 4 - hex.count) + hex
                    } else {
                        result.unicodeScalars.append(scalar)
                    }
            }
        }
        return result + "\""
    }
}
