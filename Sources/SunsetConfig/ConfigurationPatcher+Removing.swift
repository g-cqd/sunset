/// Keys taken out of a file (the owner's note n115: settings made fixed are removed from the file, not left to mislead).
extension ConfigurationPatcher {
    /// `text` without the members at the dotted `paths`, a section's whole when the path names it; what a person wrote
    /// around them (comments, spacing, other members) kept. A member on lines of its own goes with its lines; its comma
    /// goes with it. A path that is not there changes nothing. Nil when `text` is not an object.
    public static func removing(_ text: String, paths: [String]) -> String? {
        var current = Array(text.utf8)
        guard JSONSpans.parse(current)?.isObject == true else { return nil }
        for path in paths.sorted() {
            guard let tree = JSONSpans.parse(current), let range = removal(of: path, in: tree, bytes: current) else {
                continue
            }
            current.removeSubrange(range)
        }
        return String(decoding: current, as: UTF8.self)
    }

    /// The bytes that hold the member at `path`, its comma, and its lines when it has them to itself.
    private static func removal(of path: String, in root: JSONSpans, bytes: [UInt8]) -> Range<Int>? {
        var node = root
        let parts = path.split(separator: ".").map(String.init)
        for name in parts.dropLast() {
            guard let section = node.members.last(where: { $0.key == name })?.value, section.isObject else {
                return nil
            }
            node = section
        }
        guard let last = parts.last, let index = node.members.lastIndex(where: { $0.key == last }) else { return nil }
        let member = node.members[index]
        var start = member.keyStart
        var end = member.value.range.upperBound
        // Its own comma after it (a trailing one included), else the one before it when it is the last member.
        var after = end
        while after < bytes.count, bytes[after] == 0x20 || bytes[after] == 0x09 { after += 1 }
        if after < bytes.count, bytes[after] == 0x2C {
            end = after + 1
        } else if index > 0 {
            var before = node.members[index - 1].value.range.upperBound
            while before < start, bytes[before] != 0x2C { before += 1 }
            if before < start { start = before }
        }
        return lines(of: start ..< end, in: bytes)
    }

    /// `range` grown to its whole lines when nothing else is on them.
    private static func lines(of range: Range<Int>, in bytes: [UInt8]) -> Range<Int> {
        func blank(_ byte: UInt8) -> Bool {
            byte == 0x20 || byte == 0x09
        }
        var lineStart = range.lowerBound
        while lineStart > 0, blank(bytes[lineStart - 1]) { lineStart -= 1 }
        var lineEnd = range.upperBound
        while lineEnd < bytes.count, blank(bytes[lineEnd]) { lineEnd += 1 }
        guard lineStart == 0 || bytes[lineStart - 1] == 0x0A, lineEnd < bytes.count, bytes[lineEnd] == 0x0A else {
            return range
        }
        return lineStart ..< lineEnd + 1
    }
}
