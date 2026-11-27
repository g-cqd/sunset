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

extension KeyChord {
    /// A key as the file writes it: "cmd+shift+d", "cmd+opt+up"; also read as the menus write it ("⇧⌘D").
    package init?(text: String) {
        let lowered = text.lowercased().filter { $0 != " " }
        var modifiers: Modifiers = []
        var rest = Substring(lowered)
        // The menus' symbols first.
        let symbols: [(Character, Modifiers)] = [
            ("\u{2303}", .control), ("\u{2325}", .option), ("\u{21E7}", .shift), ("\u{2318}", .command)
        ]
        while let first = rest.first, let symbol = symbols.first(where: { $0.0 == first }) {
            modifiers.insert(symbol.1)
            rest = rest.dropFirst()
        }
        var parts = rest.split(separator: "+", omittingEmptySubsequences: false).map(String.init)
        // "cmd++": the key is the plus.
        if parts.count >= 2, parts.suffix(2) == ["", ""] { parts = parts.dropLast(2) + ["+"] }
        guard let last = parts.popLast(), !last.isEmpty else { return nil }
        for part in parts {
            switch part {
                case "cmd", "command": modifiers.insert(.command)
                case "shift": modifiers.insert(.shift)
                case "opt", "option", "alt": modifiers.insert(.option)
                case "ctrl", "control": modifiers.insert(.control)
                default: return nil
            }
        }
        let key: Key
        switch last {
            case "up", "\u{2191}": key = .up
            case "down", "\u{2193}": key = .down
            case "left", "\u{2190}": key = .left
            case "right", "\u{2192}": key = .right
            case "space": key = .character(" ")
            default:
                guard last.count == 1, let character = last.first else { return nil }
                key = .character(character)
        }
        // A key alone would be taken from what is typed.
        guard !modifiers.isDisjoint(with: [.command, .control]) else { return nil }
        self.init(key, modifiers)
    }

    /// As the file writes it: "cmd+shift+d".
    package var text: String {
        var parts: [String] = []
        if modifiers.contains(.control) { parts.append("ctrl") }
        if modifiers.contains(.option) { parts.append("opt") }
        if modifiers.contains(.shift) { parts.append("shift") }
        if modifiers.contains(.command) { parts.append("cmd") }
        switch key {
            case .character(" "): parts.append("space")
            case .character(let character): parts.append(String(character).lowercased())
            case .up: parts.append("up")
            case .down: parts.append("down")
            case .left: parts.append("left")
            case .right: parts.append("right")
        }
        return parts.joined(separator: "+")
    }
}
