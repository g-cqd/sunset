internal import AemiJSONCore
internal import OrderedCollections

extension Reader {
    /// `window.opacity`, from before the terminal had a section of its own: it is the terminal's opacity (a file that has both uses `terminal.opacity`).
    mutating func readLegacyWindowOpacity(_ value: JSONValue) {
        guard let factor = number("window.opacity", value, range: 0 ... 1), !terminalOpacitySet else { return }
        configuration.terminal.opacity = factor
    }

    mutating func readTerminal(_ object: Object) {
        for (key, value) in object {
            switch key {
                case "directory":
                    guard let path = string("terminal.directory", value) else { continue }
                    configuration.terminal.directory = path
                default: unknown("terminal.\(key)")
            }
        }
    }
}
