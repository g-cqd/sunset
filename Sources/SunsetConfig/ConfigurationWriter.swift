/// Writes a configuration as the text of a file: every key, so that the file shows what can be set. Colours not set are written as null, a font with no family
/// as an empty string, a cursor that blinks for ever as null.
public enum ConfigurationWriter {
    public static func text(for configuration: Configuration) -> String {
        let font = configuration.font
        let colors = configuration.colors
        let window = configuration.window
        let timeout = configuration.cursorBlinkTimeout.map(number) ?? "null"
        return """
            {
              "font": {
                "family": \(string(font.family ?? "")),
                "size": \(number(font.size)),
                "ligatures": \(font.ligatures),
                "features": \(string(font.features))
              },
              "colors": {
                "foreground": \(color(colors.foreground)),
                "background": \(color(colors.background)),
                "cursor": \(color(colors.cursor))
              },
              "window": {
                "decorations": \(string(window.decorations.rawValue)),
                "trafficLights": { "x": \(number(window.trafficLightsX)), "y": \(number(window.trafficLightsY)) },
                "dragStrip": \(number(window.dragStrip))
              },
              "scroll": {
                "trackpad": \(number(configuration.scroll.trackpad)),
                "wheel": \(number(configuration.scroll.wheel))
              },
              "scrollback": { "lines": \(configuration.scrollbackLines) },
              "cursor": { "blinkTimeout": \(timeout) },
              "renderer": \(string(configuration.renderer.rawValue)),
              "keyboard": { "optionAsMeta": \(configuration.keyboard.optionAsMeta) }
            }

            """
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
