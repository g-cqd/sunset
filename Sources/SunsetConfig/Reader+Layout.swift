internal import AemiJSONCore
internal import OrderedCollections
import SunsetMetrics

extension Reader {
    mutating func readLayout(_ object: Object) {
        for (key, value) in object {
            let path = "layout.\(key)"
            // The names before 2026-11-12 (they said "pin" for every sidebar button).
            let key = ["pinButtonSize": "sidebarButtonSize", "pinButtonRadius": "sidebarButtonRadius"][key] ?? key
            if let field = Configuration.Layout.fields.first(where: { $0.key == key }) {
                if let number = number(path, value, range: field.range) {
                    configuration.layout[keyPath: field.path] = number
                }
            } else if key == "terminalRadius" {
                if let radius = optionalRadius(path, value) { configuration.layout.terminalRadius = radius.value }
            } else if key == "panelRadius" {
                if let radius = optionalRadius(path, value) { configuration.layout.panelRadius = radius.value }
            } else {
                unknown(path)
            }
        }
    }

    /// A radius in points, or null for "follow the window": nil when the value is wrong (an issue is recorded), else a box with the value.
    private mutating func optionalRadius(_ path: String, _ value: JSONValue) -> Box? {
        if case .null = value { return Box(value: nil) }
        return number(path, value, range: 0 ... 40).map { Box(value: $0) }
    }

    private struct Box { var value: Double? }
}
