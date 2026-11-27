/// A key with its modifiers, as a menu item's shortcut: the key a command is run by.
package struct KeyChord: Hashable, Sendable {
    package enum Key: Hashable, Sendable {
        case character(Character)
        case up, down, left, right
    }

    package struct Modifiers: OptionSet, Hashable, Sendable {
        package let rawValue: UInt8
        package init(rawValue: UInt8) {
            self.rawValue = rawValue
        }

        package static let command = Self(rawValue: 1 << 0)
        package static let shift = Self(rawValue: 1 << 1)
        package static let option = Self(rawValue: 1 << 2)
        package static let control = Self(rawValue: 1 << 3)
    }

    package let key: Key
    package let modifiers: Modifiers

    package init(_ key: Key, _ modifiers: Modifiers = .command) {
        self.key = key
        self.modifiers = modifiers
    }

    package init(_ character: Character, _ modifiers: Modifiers = .command) {
        self.init(.character(character), modifiers)
    }

    /// As the menus write it: ⌃⌥⇧⌘ then the key ("⇧⌘D").
    package var symbols: String {
        var text = ""
        if modifiers.contains(.control) { text += "\u{2303}" }
        if modifiers.contains(.option) { text += "\u{2325}" }
        if modifiers.contains(.shift) { text += "\u{21E7}" }
        if modifiers.contains(.command) { text += "\u{2318}" }
        switch key {
            case .character(let character): text += String(character).uppercased()
            case .up: text += "\u{2191}"
            case .down: text += "\u{2193}"
            case .left: text += "\u{2190}"
            case .right: text += "\u{2192}"
        }
        return text
    }
}
