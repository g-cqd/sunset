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
                case "opacity":
                    if let factor = number("terminal.opacity", value, range: 0 ... 1) {
                        configuration.terminal.opacity = factor
                        terminalOpacitySet = true
                    }
                case "clipboardWrite":
                    guard let flag = bool("terminal.clipboardWrite", value) else { continue }
                    configuration.terminal.clipboardWrite = flag
                case "shellIntegration":
                    guard let flag = bool("terminal.shellIntegration", value) else { continue }
                    configuration.terminal.shellIntegration = flag
                default: unknown("terminal.\(key)")
            }
        }
    }
}
