/// Edits the text of a configuration file in place, so that what a person wrote (comments, order, spacing) is kept.
public enum ConfigurationPatcher {
    /// `text` with each dotted path in `values` set to its JSON literal: an existing value is replaced, a missing key is added to its section (the section is
    /// added if it is missing too). Nil when `text` is not an object. Paths are applied one after the other, each on the result of the one before, in sorted
    /// order, so the result does not depend on the dictionary's order.
    public static func patch(_ text: String, set values: [String: String]) -> String? {
        var current = Array(text.utf8)
        guard var tree = JSONSpans.parse(current), tree.isObject else { return nil }
        for path in values.keys.sorted() {
            guard let literal = values[path] else { continue }
            let parts = path.split(separator: ".").map(String.init)
            let edit = edit(for: parts, literal: literal, in: tree, bytes: current)
            current.replaceSubrange(edit.range, with: Array(edit.replacement.utf8))
            guard let next = JSONSpans.parse(current) else { return nil }
            tree = next
        }
        return String(decoding: current, as: UTF8.self)
    }

    /// `text` changed so that it says `configuration`: only the keys whose value differs from what `text` says now are written. Nil when `text` is not a
    /// readable configuration (the caller then writes the whole file).
    public static func saved(_ configuration: Configuration, over text: String) -> String? {
        guard let current = try? ConfigurationParser.parse(text).configuration else { return nil }
        let before = ConfigurationWriter.literals(for: current)
        let wanted = ConfigurationWriter.literals(for: configuration).filter { before[$0.key] != $0.value }
        return patch(text, set: wanted)
    }

    private struct Edit {
        var range: Range<Int>
        var replacement: String
    }

    /// Where and what to write to set `parts` to `literal`.
    private static func edit(for parts: [String], literal: String, in root: JSONSpans, bytes: [UInt8]) -> Edit {
        var node = root
        for (depth, name) in parts.enumerated() {
            let last = depth == parts.count - 1
            // The last member with this name is the one in force.
            guard let member = node.members.last(where: { $0.key == name }) else {
                return insertion(of: Array(parts[depth...]), literal: literal, into: node, bytes: bytes)
            }
            if last { return Edit(range: member.value.range, replacement: literal) }
            guard member.value.isObject else {
                // Not a section: replaced by one holding the rest of the path.
                return Edit(
                    range: member.value.range,
                    replacement: nested(Array(parts[(depth + 1)...]), literal: literal)
                )
            }
            node = member.value
        }
        return Edit(range: node.range, replacement: literal)
    }

    /// `{ "a": { "b": literal } }` for the path `a.b`.
    private static func nested(_ parts: [String], literal: String) -> String {
        guard let first = parts.first else { return literal }
        return "{ " + quoted(first) + ": " + nested(Array(parts.dropFirst()), literal: literal) + " }"
    }

    private static func insertion(of parts: [String], literal: String, into object: JSONSpans, bytes: [UInt8]) -> Edit {
        let member = quoted(parts[0]) + ": " + nested(Array(parts.dropFirst()), literal: literal)
        if let last = object.members.last {
            let indent = indentation(before: last.keyStart, in: bytes)
            let at = last.value.range.upperBound
            return Edit(range: at ..< at, replacement: ",\n" + indent + member)
        }
        // An empty object: the first member goes on its own line, indented one level more than the line the object starts on.
        let base = indentation(before: object.range.lowerBound, in: bytes)
        let close = object.range.upperBound - 1
        let closing = indentation(before: close, in: bytes)
        let inline = !bytes[object.range.lowerBound ..< close].contains(0x0A)
        let text = "\n" + base + "  " + member + "\n" + (inline ? base : closing)
        return Edit(range: (object.range.lowerBound + 1) ..< close, replacement: text)
    }

    /// The whitespace at the start of the line that holds `offset`, when that is all that precedes the first non-blank character; else the line's indent.
    private static func indentation(before offset: Int, in bytes: [UInt8]) -> String {
        var start = offset
        while start > 0, bytes[start - 1] != 0x0A { start -= 1 }
        var end = start
        while end < bytes.count, bytes[end] == 0x20 || bytes[end] == 0x09 { end += 1 }
        return String(decoding: bytes[start ..< end], as: UTF8.self)
    }

    private static func quoted(_ name: String) -> String { "\"" + name + "\"" }
}
