extension ConfigurationPatcher {
    /// `text` with the settings at their former keys moved to the file's keys (design 0009), each as it was written: a key
    /// set in both places keeps the new one. Nil when `text` is not an object.
    public static func movingFormerKeys(_ text: String) -> String? {
        var current = text
        for move in FileKeys.moves {
            let bytes = Array(current.utf8)
            guard let tree = JSONSpans.parse(bytes), tree.isObject else { return nil }
            guard let old = span(of: move.inside, in: tree) else { continue }
            let literal = String(decoding: bytes[old], as: UTF8.self)
            let moved =
                span(of: move.file, in: tree) == nil ? patch(current, set: [move.file: literal]) : current
            guard let moved, let removed = removing(moved, paths: [move.inside]) else { return nil }
            current = removed
        }
        return current
    }

    /// Where the value at the dotted `path` is written.
    private static func span(of path: String, in root: JSONSpans) -> Range<Int>? {
        var node = root
        for name in path.split(separator: ".").map(String.init) {
            guard node.isObject, let member = node.members.last(where: { $0.key == name }) else { return nil }
            node = member.value
        }
        return node.range
    }
}
