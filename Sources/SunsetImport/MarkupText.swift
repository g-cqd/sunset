/// The text of loose HTML: character references made characters, white space gathered.
enum MarkupText {
    /// The few named references bookmark files use; the rest are written as numbers.
    static func named(_ name: Substring) -> Character? {
        switch name {
            case "amp": "&"
            case "lt": "<"
            case "gt": ">"
            case "quot": "\""
            case "apos": "'"
            case "nbsp": " "
            default: nil
        }
    }

    /// `text` with `&amp;`, `&#39;`, `&#x2F;` and the like replaced; a reference it does not know is left as written.
    static func unescaped(_ text: Substring) -> String {
        guard text.contains("&") else { return String(text) }
        var result = ""
        var rest = text
        while let amp = rest.firstIndex(of: "&") {
            result += rest[..<amp]
            let after = rest[rest.index(after: amp)...]
            if let semicolon = after.prefix(10).firstIndex(of: ";"), let character = character(after[..<semicolon]) {
                result.append(character)
                rest = after[after.index(after: semicolon)...]
            } else {
                result.append("&")
                rest = after
            }
        }
        return result + rest
    }

    /// A title: unescaped, its runs of white space one space, trimmed.
    static func title(_ text: Substring) -> String {
        unescaped(text).split(whereSeparator: \.isWhitespace).joined(separator: " ")
    }

    private static func character(_ reference: Substring) -> Character? {
        guard reference.first == "#" else { return named(reference) }
        let digits = reference.dropFirst()
        let value = digits.first == "x" || digits.first == "X" ? UInt32(digits.dropFirst(), radix: 16) : UInt32(digits)
        return value.flatMap(Unicode.Scalar.init).map(Character.init)
    }
}
