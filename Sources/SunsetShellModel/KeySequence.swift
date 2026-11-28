/// The keys a command is run by: one key, or two pressed one after the other ("⌘K ⌘T"), as editors' chords.
package struct KeySequence: Hashable, Sendable {
    package let first: KeyChord
    /// The second key, pressed after the first; nil: the first alone.
    package let then: KeyChord?

    package init(_ first: KeyChord, then: KeyChord? = nil) {
        self.first = first
        self.then = then
    }

    /// As the file writes it: one key or two, apart ("cmd+k cmd+t", "cmd+k, cmd+t", "⌘K ⌘T").
    package init?(text: String) {
        let parts = text.split { $0 == " " || $0 == "," }.map(String.init)
        guard (1 ... 2).contains(parts.count), let first = KeyChord(text: parts[0]) else { return nil }
        if parts.count == 2 {
            guard let then = KeyChord(text: parts[1], alone: true) else { return nil }
            self.init(first, then: then)
        } else {
            self.init(first)
        }
    }

    /// As the file writes it: "cmd+k cmd+t".
    package var text: String {
        [first.text, then?.text].compactMap(\.self).joined(separator: " ")
    }

    /// As the menus write it: "⌘K ⌘T".
    package var symbols: String {
        [first.symbols, then?.symbols].compactMap(\.self).joined(separator: " ")
    }

    /// The key alone, for a menu item (which shows one key, not two).
    package var single: KeyChord? {
        then == nil ? first : nil
    }
}
