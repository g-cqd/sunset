package import AppKit
package import SunsetCore

/// Turns AppKit key events into the terminal's own key model (`KeyPress`), for the keys that are not plain text; plain text goes through the text input
/// system, which composes dead keys and input methods.
package enum KeyboardMapping {
    /// The key for a hardware key code that has a name, or nil for the keys that produce text.
    package static func namedKey(_ keyCode: UInt16) -> KeyCode? {
        switch keyCode {
            case 36, 76: .enter
            case 48: .tab
            case 51: .backspace
            case 53: .escape
            case 126: .up
            case 125: .down
            case 123: .left
            case 124: .right
            case 115: .home
            case 119: .end
            case 116: .pageUp
            case 121: .pageDown
            case 114: .insert
            case 117: .delete
            case 122: .function(1)
            case 120: .function(2)
            case 99: .function(3)
            case 118: .function(4)
            case 96: .function(5)
            case 97: .function(6)
            case 98: .function(7)
            case 100: .function(8)
            case 101: .function(9)
            case 109: .function(10)
            case 103: .function(11)
            case 111: .function(12)
            default: nil
        }
    }

    package static func modifiers(_ flags: NSEvent.ModifierFlags) -> InputModifiers {
        var result: InputModifiers = []
        if flags.contains(.shift) { result.insert(.shift) }
        if flags.contains(.option) { result.insert(.option) }
        if flags.contains(.control) { result.insert(.control) }
        return result
    }

    /// The press for `event` when it must go to the program as a key and not as text: a named key, a Control combination, or Option used as Meta. Nil when
    /// the text input system should handle it (and for Command combinations, which belong to the app's menus).
    package static func press(for event: NSEvent, optionAsMeta: Bool) -> KeyPress? {
        let held = event.modifierFlags
        if held.contains(.command) { return nil }
        let mapped = modifiers(held)
        if let named = namedKey(event.keyCode) { return KeyPress(named, modifiers: mapped) }
        let base = event.charactersIgnoringModifiers ?? ""
        guard let scalar = base.unicodeScalars.first else { return nil }
        if held.contains(.control) || (held.contains(.option) && optionAsMeta) {
            return KeyPress(.character(scalar), modifiers: mapped, text: base)
        }
        return nil
    }
}
