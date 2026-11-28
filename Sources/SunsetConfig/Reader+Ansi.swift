internal import AemiJSONCore

extension Reader {
    /// `colors.ansi`: an array of up to 16 `#rrggbb` strings that set the first ANSI colours; an entry that is not a colour is reported and keeps its default.
    mutating func readAnsi(_ key: String, _ value: JSONValue) {
        guard case .array(let entries) = value, entries.count <= 16 else {
            issue(key, "expected an array of at most 16 colours written #rrggbb")
            return
        }
        for (index, entry) in entries.enumerated() {
            if let bytes = color("\(key)[\(index)]", entry) { configuration.colors.ansi[index] = bytes }
        }
    }
}
