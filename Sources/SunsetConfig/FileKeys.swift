internal import AemiJSONCore
internal import OrderedCollections

/// The file's keys follow Settings' sections (design 0009): the terminal's under `terminal`, the window's background under
/// `appearance`, the documents' order under `documents`. Inside, the settings keep their former names; the file is
/// translated as it is read and written, and a file with the former keys is still read.
public enum FileKeys {
    /// A setting's name inside, and where the file has it: the first that is it or a section of it applies.
    static let moves: [(inside: String, file: String)] = table.split(whereSeparator: \.isWhitespace)
        .map { pair in
            let sides = pair.split(separator: ">").map(String.init)
            return (sides[0], sides[1])
        }

    /// `inside>file`, one move a word.
    private static let table = """
        font>terminal.font
        colors>terminal.colors
        cursor>terminal.cursor
        scrollback.lines>terminal.scrollback
        scroll>terminal.scroll
        keyboard.optionAsMeta>terminal.optionAsMeta
        window.padding>terminal.padding
        window.material>appearance.material
        window.materialThickness>appearance.materialThickness
        window.blur>appearance.blur
        sidebar.documentSort>documents.sort
        features.credentials>features.passwords
        """

    /// Where the file has the setting named `inside`.
    public static func file(_ inside: String) -> String {
        translate(inside, from: \.inside, to: \.file)
    }

    /// The setting the file's key `file` is.
    public static func inside(_ file: String) -> String {
        translate(file, from: \.file, to: \.inside)
    }

    /// Whether the file's top level has a key in its former place (`font`, `colors`, …): it is then written again.
    static func hasFormerKeys(_ root: OrderedDictionary<String, JSONValue>) -> Bool {
        moves.contains { move in
            let parts = move.inside.split(separator: ".").map(String.init)
            return value(at: parts, in: root) != nil && move.inside != move.file
        }
    }

    /// `root` with what is at the file's keys moved to the settings' own: a value given in both places is the file's new one.
    static func inside(_ root: OrderedDictionary<String, JSONValue>) -> OrderedDictionary<String, JSONValue> {
        var root = root
        for move in moves {
            let from = move.file.split(separator: ".").map(String.init)
            guard let value = take(from, in: &root) else { continue }
            put(value, at: move.inside.split(separator: ".").map(String.init), in: &root)
        }
        return root
    }

    /// `keys` ordered so that each section's keys are together, sections in the order their first key comes.
    static func grouped(_ keys: [String]) -> [String] {
        var order: [String] = []
        var members: [String: [String]] = [:]
        for key in keys {
            let parts = key.split(separator: ".", maxSplits: 1).map(String.init)
            let head = parts[0]
            if members[head] == nil { order.append(head) }
            members[head, default: []].append(parts.count > 1 ? parts[1] : "")
        }
        return order.flatMap { head -> [String] in
            let rest = members[head] ?? []
            if rest == [""] { return [head] }
            return grouped(rest.filter { !$0.isEmpty }).map { "\(head).\($0)" }
        }
    }

    private static func translate(
        _ name: String,
        from: KeyPath<(inside: String, file: String), String>,
        to: KeyPath<(inside: String, file: String), String>
    ) -> String {
        for move in moves {
            let prefix = move[keyPath: from]
            if name == prefix { return move[keyPath: to] }
            if name.hasPrefix(prefix + ".") { return move[keyPath: to] + name.dropFirst(prefix.count) }
        }
        return name
    }

    private static func value(at parts: [String], in object: OrderedDictionary<String, JSONValue>) -> JSONValue? {
        guard let first = parts.first, let value = object[first] else { return nil }
        guard parts.count > 1 else { return value }
        guard case .object(let inner) = value else { return nil }
        return Self.value(at: Array(parts.dropFirst()), in: inner)
    }

    /// Removes and returns what is at `parts`; a section left empty is removed too.
    private static func take(_ parts: [String], in object: inout OrderedDictionary<String, JSONValue>) -> JSONValue? {
        guard let first = parts.first, let value = object[first] else { return nil }
        guard parts.count > 1 else { return object.removeValue(forKey: first) }
        guard case .object(var inner) = value else { return nil }
        let taken = take(Array(parts.dropFirst()), in: &inner)
        object[first] = inner.isEmpty ? nil : .object(inner)
        return taken
    }

    /// Puts `value` at `parts`, merging into a section that is there.
    private static func put(
        _ value: JSONValue,
        at parts: [String],
        in object: inout OrderedDictionary<String, JSONValue>
    ) {
        guard let first = parts.first else { return }
        if parts.count == 1 {
            if case .object(let new) = value, case .object(var old) = object[first] {
                for (key, member) in new { old[key] = member }
                object[first] = .object(old)
            } else {
                object[first] = value
            }
            return
        }
        var inner: OrderedDictionary<String, JSONValue> = [:]
        if case .object(let existing) = object[first] { inner = existing }
        put(value, at: Array(parts.dropFirst()), in: &inner)
        object[first] = .object(inner)
    }
}
