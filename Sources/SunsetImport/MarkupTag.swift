/// A tag of loose HTML: its name in lower case, whether it closes, and its attributes as written (names in lower case,
/// values unescaped).
struct MarkupTag: Equatable {
    let name: String
    let isClosing: Bool
    let attributes: [String: String]

    /// The tag `source` holds, between `<` and `>` (both left out); nil for a comment or a declaration.
    init?(_ source: Substring) {
        guard let first = source.first, first != "!", first != "?" else { return nil }
        isClosing = first == "/"
        let body = isClosing ? source.dropFirst() : source
        let nameEnd = body.firstIndex { $0.isWhitespace || $0 == "/" } ?? body.endIndex
        name = body[..<nameEnd].lowercased()
        attributes = Self.attributes(body[nameEnd...])
    }

    /// `name=value`, `name="value"`, `name='value'` and bare names, as they come.
    private static func attributes(_ text: Substring) -> [String: String] {
        var result: [String: String] = [:]
        var rest = text[...]
        while true {
            rest = rest.drop { $0.isWhitespace || $0 == "/" }
            guard !rest.isEmpty else { return result }
            let nameEnd = rest.firstIndex { $0.isWhitespace || $0 == "=" } ?? rest.endIndex
            let name = rest[..<nameEnd].lowercased()
            rest = rest[nameEnd...].drop { $0.isWhitespace }
            guard rest.first == "=" else {
                result[name] = ""
                continue
            }
            rest = rest.dropFirst().drop { $0.isWhitespace }
            let value: Substring
            if let quote = rest.first, quote == "\"" || quote == "'" {
                let inside = rest.dropFirst()
                let end = inside.firstIndex(of: quote) ?? inside.endIndex
                value = inside[..<end]
                rest = end < inside.endIndex ? inside[inside.index(after: end)...] : inside[end...]
            } else {
                let end = rest.firstIndex { $0.isWhitespace } ?? rest.endIndex
                value = rest[..<end]
                rest = rest[end...]
            }
            result[name] = MarkupText.unescaped(value)
        }
    }
}
