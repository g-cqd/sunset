/// Modifier keys held with a key press. (Command is the host's: it never reaches the program.)
public struct InputModifiers: OptionSet, Sendable {
    public let rawValue: UInt8
    public init(rawValue: UInt8) { self.rawValue = rawValue }

    public static let shift = InputModifiers(rawValue: 1 << 0)
    public static let option = InputModifiers(rawValue: 1 << 1)
    public static let control = InputModifiers(rawValue: 1 << 2)
}

/// A key, as the host reports it: the character keys by the character they are (the unshifted one), the others by name.
public enum KeyCode: Sendable, Equatable {
    case character(Unicode.Scalar)
    case enter, tab, backspace, escape
    case up, down, left, right
    case home, end, pageUp, pageDown, insert, delete
    /// F1 ... F24.
    case function(Int)
}

public struct KeyPress: Sendable, Equatable {
    public var code: KeyCode
    public var modifiers: InputModifiers
    /// The text the key produced with the modifiers applied (shift, dead keys and the keyboard layout included), for character keys; empty or nil for the others.
    public var text: String?

    public init(_ code: KeyCode, modifiers: InputModifiers = [], text: String? = nil) {
        self.code = code
        self.modifiers = modifiers
        self.text = text
    }
}

/// Turns key presses into the bytes a program reads: the legacy xterm encodings (which every program understands), and the kitty keyboard protocol's
/// "disambiguate escape codes" level when the program asked for it. A pure function of the key, the terminal's modes and the protocol flags.
public enum KeyEncoder {
    public static func encode(_ press: KeyPress, modes: Modes, keyboardFlags: UInt8 = 0) -> [UInt8] {
        let disambiguate = keyboardFlags & 1 != 0
        switch press.code {
            case .character(let scalar): return character(scalar, press, disambiguate: disambiguate)
            case .enter: return plainOrDisambiguated(13, [13], press, disambiguate: disambiguate)
            case .tab:
                if press.modifiers == [.shift] { return Array("\u{1B}[Z".utf8) }
                return plainOrDisambiguated(9, [9], press, disambiguate: disambiguate)
            case .backspace:
                return plainOrDisambiguated(
                    127,
                    press.modifiers.contains(.control) ? [8] : [127],
                    press,
                    disambiguate: disambiguate
                )
            case .escape: return disambiguate ? csi("27", press.modifiers, final: "u") : prefixed([0x1B], press)
            case .up: return cursorKey("A", press, modes: modes)
            case .down: return cursorKey("B", press, modes: modes)
            case .right: return cursorKey("C", press, modes: modes)
            case .left: return cursorKey("D", press, modes: modes)
            case .home: return cursorKey("H", press, modes: modes)
            case .end: return cursorKey("F", press, modes: modes)
            case .pageUp: return tilde(5, press)
            case .pageDown: return tilde(6, press)
            case .insert: return tilde(2, press)
            case .delete: return tilde(3, press)
            case .function(let number): return functionKey(number, press)
        }
    }

    // MARK: Pieces

    private static func modifierParameter(_ modifiers: InputModifiers) -> Int {
        1 + (modifiers.contains(.shift) ? 1 : 0) + (modifiers.contains(.option) ? 2 : 0)
            + (modifiers.contains(.control) ? 4 : 0)
    }

    private static func csi(_ parameter: String, _ modifiers: InputModifiers, final: Character) -> [UInt8] {
        let suffix = modifiers.isEmpty ? "" : ";\(modifierParameter(modifiers))"
        return Array("\u{1B}[\(parameter)\(suffix)\(final)".utf8)
    }

    /// Alt (Option as Meta) sends ESC before whatever the key sends.
    private static func prefixed(_ bytes: [UInt8], _ press: KeyPress) -> [UInt8] {
        press.modifiers.contains(.option) ? [0x1B] + bytes : bytes
    }

    private static func plainOrDisambiguated(_ code: Int, _ legacy: [UInt8], _ press: KeyPress, disambiguate: Bool)
        -> [UInt8]
    {
        // With the keyboard protocol on, a modified Enter, Tab or Backspace is a CSI u (the legacy bytes cannot say which modifier it was).
        if disambiguate,
            !press.modifiers.subtracting(.shift).isEmpty || (press.modifiers.contains(.shift) && code != 13)
        {
            return csi(String(code), press.modifiers, final: "u")
        }
        return prefixed(legacy, press)
    }

    private static func character(_ scalar: Unicode.Scalar, _ press: KeyPress, disambiguate: Bool) -> [UInt8] {
        let control = press.modifiers.contains(.control)
        let option = press.modifiers.contains(.option)
        if disambiguate, control || option {
            let lower = Character(scalar).lowercased().unicodeScalars.first!.value
            return csi(String(lower), press.modifiers, final: "u")
        }
        if control, let byte = controlByte(scalar) { return prefixed([byte], press) }
        let text = press.text ?? String(scalar)
        return prefixed(Array(text.utf8), press)
    }

    /// The control character for Ctrl with this key: letters give 1...26, and the punctuation of the ASCII chart its 0, 27...31 and 127.
    private static func controlByte(_ scalar: Unicode.Scalar) -> UInt8? {
        switch scalar.value {
            case 0x61 ... 0x7A: return UInt8(scalar.value - 0x60)
            case 0x41 ... 0x5A: return UInt8(scalar.value - 0x40)
            case 0x20, 0x40, 0x32: return 0
            case 0x5B, 0x33: return 27
            case 0x5C, 0x34: return 28
            case 0x5D, 0x35: return 29
            case 0x5E, 0x36: return 30
            case 0x5F, 0x37: return 31
            case 0x3F: return 127
            default: return nil
        }
    }

    private static func cursorKey(_ final: Character, _ press: KeyPress, modes: Modes) -> [UInt8] {
        if !press.modifiers.isEmpty { return csi("1", press.modifiers, final: final) }
        return Array((modes.applicationCursorKeys ? "\u{1B}O\(final)" : "\u{1B}[\(final)").utf8)
    }

    private static func tilde(_ number: Int, _ press: KeyPress) -> [UInt8] {
        csi(String(number), press.modifiers, final: "~")
    }

    private static func functionKey(_ number: Int, _ press: KeyPress) -> [UInt8] {
        switch number {
            case 1 ... 4:
                let final = Character(Unicode.Scalar(UInt8(0x50 + number - 1)))
                if press.modifiers.isEmpty { return Array("\u{1B}O\(final)".utf8) }
                return csi("1", press.modifiers, final: final)
            case 5: return tilde(15, press)
            case 6 ... 10: return tilde(17 + number - 6, press)
            case 11, 12: return tilde(23 + number - 11, press)
            case 13 ... 16: return tilde(25 + number - 13, press)
            case 17, 18: return tilde(31 + number - 17, press)
            case 19, 20: return tilde(33 + number - 19, press)
            default: return []
        }
    }
}

/// Text pasted into the terminal, as the program should read it.
public enum PasteEncoder {
    /// With bracketed paste on the text is wrapped in `ESC [ 200 ~` ... `ESC [ 201 ~` so the program can tell it from typing, and the end marker is removed from
    /// the text (a paste must not be able to close its own brackets and have the rest read as typed commands). Without it, line feeds become carriage returns,
    /// as the Enter key sends.
    public static func encode(_ text: String, bracketed: Bool) -> [UInt8] {
        let bytes = Array(text.utf8)
        if bracketed {
            let marker = Array("\u{1B}[201~".utf8)
            // Removed until none is left: taking one out of "ESC [ 201 ESC [ 201 ~ ~" leaves another.
            var cleaned = bytes
            var changed = true
            while changed {
                changed = false
                var next: [UInt8] = []
                var index = 0
                while index < cleaned.count {
                    if index + marker.count <= cleaned.count, Array(cleaned[index ..< index + marker.count]) == marker {
                        index += marker.count
                        changed = true
                    } else {
                        next.append(cleaned[index])
                        index += 1
                    }
                }
                cleaned = next
            }
            return Array("\u{1B}[200~".utf8) + cleaned + marker
        }
        var result: [UInt8] = []
        var index = 0
        while index < bytes.count {
            if bytes[index] == 0x0D, index + 1 < bytes.count, bytes[index + 1] == 0x0A {
                result.append(0x0D)
                index += 2
            } else {
                result.append(bytes[index] == 0x0A ? 0x0D : bytes[index])
                index += 1
            }
        }
        return result
    }
}
