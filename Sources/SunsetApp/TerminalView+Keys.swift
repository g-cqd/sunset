import AppKit
import SunsetCore

extension TerminalView {
    func keyPress(from event: NSEvent) -> KeyPress? {
        var modifiers: InputModifiers = []
        if event.modifierFlags.contains(.shift) { modifiers.insert(.shift) }
        if event.modifierFlags.contains(.option) { modifiers.insert(.option) }
        if event.modifierFlags.contains(.control) { modifiers.insert(.control) }
        if event.modifierFlags.contains(.command) { return nil }
        let code: KeyCode
        switch event.keyCode {
            case 36, 76: code = .enter
            case 48: code = .tab
            case 51: code = .backspace
            case 53: code = .escape
            case 126: code = .up
            case 125: code = .down
            case 123: code = .left
            case 124: code = .right
            case 115: code = .home
            case 119: code = .end
            case 116: code = .pageUp
            case 121: code = .pageDown
            case 114: code = .insert
            case 117: code = .delete
            case 122: code = .function(1)
            case 120: code = .function(2)
            case 99: code = .function(3)
            case 118: code = .function(4)
            case 96: code = .function(5)
            case 97: code = .function(6)
            case 98: code = .function(7)
            case 100: code = .function(8)
            case 101: code = .function(9)
            case 109: code = .function(10)
            case 103: code = .function(11)
            case 111: code = .function(12)
            default:
                // Option as Meta: the character the key is, not what Option makes of it.
                let base = event.charactersIgnoringModifiers ?? ""
                guard let scalar = base.unicodeScalars.first else { return nil }
                let text = modifiers.contains(.option) ? base : event.characters
                return KeyPress(.character(scalar), modifiers: modifiers, text: text)
        }
        return KeyPress(code, modifiers: modifiers)
    }
}
