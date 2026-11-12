/// Writes a configuration as the text of a file: every key, so that the file shows what can be set. Colours not set are written as null, a font with no family
/// as an empty string, a cursor that blinks for ever as null.
public enum ConfigurationWriter {
    /// Every key of the file with its value as a JSON literal, by dotted path.
    public static func literals(for configuration: Configuration) -> [String: String] {
        let font = configuration.font
        let colors = configuration.colors
        let window = configuration.window
        var layout: [String: String] = [:]
        layout["colors.ansi"] = "[" + colors.ansi.map { color($0) }.joined(separator: ", ") + "]"
        for field in Configuration.Layout.fields {
            layout["layout.\(field.key)"] = number(configuration.layout[keyPath: field.path])
        }
        layout.merge(web(configuration.web)) { $1 }
        return layout.merging([
            "font.family": string(font.family ?? ""),
            "font.size": number(font.size),
            "font.ligatures": String(font.ligatures),
            "font.features": string(font.features),
            "colors.foreground": color(colors.foreground),
            "colors.background": color(colors.background),
            "colors.cursor": color(colors.cursor),
            "window.decorations": string(window.decorations.rawValue),
            "window.trafficLights.x": number(window.trafficLightsX),
            "window.trafficLights.y": number(window.trafficLightsY),
            "window.dragStrip": number(window.dragStrip),
            "scroll.trackpad": number(configuration.scroll.trackpad),
            "scroll.wheel": number(configuration.scroll.wheel),
            "scroll.inertia": number(configuration.scroll.inertia),
            "scrollback.lines": String(configuration.scrollbackLines),
            "cursor.shape": string(configuration.cursorShape.rawValue),
            "cursor.blink": String(configuration.cursorBlinks),
            "cursor.blinkTimeout": configuration.cursorBlinkTimeout.map(number) ?? "null",
            "renderer": string(configuration.renderer.rawValue),
            "keyboard.optionAsMeta": String(configuration.keyboard.optionAsMeta),
            "window.padding": number(window.padding),
            "window.material": string(window.material.rawValue),
            "terminal.opacity": number(configuration.terminal.opacity),
            "terminal.clipboardWrite": String(configuration.terminal.clipboardWrite),
            "terminal.shellIntegration": String(configuration.terminal.shellIntegration),
            "window.blur": number(window.blur),
            "sidebar.enabled": String(configuration.sidebar.enabled),
            "sidebar.width": number(configuration.sidebar.width),
            "sidebar.padding": number(configuration.sidebar.padding),
            "sidebar.autoHide": configuration.sidebar.autoHide ? "true" : "false",
            "sidebar.side": string(configuration.sidebar.side.rawValue),
            "window.trafficLights.side": string(window.lightsSide.rawValue),
            "appearance.glass": string(configuration.appearance.glass.rawValue),
            "appearance.scheme": string(configuration.appearance.scheme.rawValue),
            "appearance.tint.color": color(configuration.appearance.tintColor),
            "appearance.tint.alpha": number(configuration.appearance.tintAlpha),
            "tabs.mode": string(configuration.tabs.mode.rawValue),
            "tabs.restore": String(configuration.tabs.restore),
            "tabs.confirmClose": String(configuration.tabs.confirmClose),
            "tabs.keepRunningForFavorites": String(configuration.tabs.keepRunningForFavorites),
            "tabs.bar.position": string(configuration.tabs.bar.position.rawValue),
            "tabs.bar.icon": String(configuration.tabs.bar.showIcon),
            "tabs.bar.title": String(configuration.tabs.bar.showTitle),
            "tabs.bar.directory": String(configuration.tabs.bar.showDirectory),
            "tabs.bar.progress": String(configuration.tabs.bar.showProgress),
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

    private static func web(_ web: Configuration.Web) -> [String: String] {
        [
            "web.openLinksInSunset": String(web.openLinksInSunset), "web.developer": String(web.developer),
            "web.tabIcon": string(web.tabIcon.rawValue), "web.address": string(web.address.rawValue),
            "web.windowBar": string(web.windowBar.rawValue), "web.engine": string(web.engine),
            "web.engines": "[" + web.engines.map(engine).joined(separator: ", ") + "]",
            "web.suggestions": String(web.suggestions), "web.httpFallback": String(web.httpFallback),
            "web.zoomScope": string(web.zoomScope.rawValue), "web.textOnlyZoom": String(web.textOnlyZoom)
        ]
    }

    private static func engine(_ engine: Configuration.Web.Engine) -> String {
        var fields = [
            "\"name\": " + string(engine.name), "\"keyword\": " + string(engine.keyword),
            "\"search\": " + string(engine.search)
        ]
        if let suggest = engine.suggest { fields.append("\"suggest\": " + string(suggest)) }
        return "{ " + fields.joined(separator: ", ") + " }"
    }

    private static func number(_ value: Double) -> String {
        value == value.rounded() && abs(value) < 1e15 ? String(Int(value)) : String(value)
    }

    private static func color(_ bytes: [UInt8]?) -> String {
        guard let bytes, bytes.count == 3 else { return "null" }
        let digits = Array("0123456789abcdef")
        return "\"#" + bytes.map { String([digits[Int($0 >> 4)], digits[Int($0 & 15)]]) }.joined() + "\""
    }

    private static func string(_ text: String) -> String {
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
