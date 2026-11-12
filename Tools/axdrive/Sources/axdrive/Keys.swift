import CoreGraphics
import Foundation

/// Keys sent to one process (`CGEvent.postToPid`): the app gets them in its key window without being brought to the front.
enum Keys {
    static let named: [String: CGKeyCode] = [
        "return": 36, "enter": 36, "tab": 48, "space": 49, "delete": 51, "escape": 53, "esc": 53, "left": 123,
        "right": 124, "down": 125,
        "up": 126, "home": 115, "end": 119, "pageup": 116, "pagedown": 121
    ]
    /// The US layout's codes, for shortcuts ("cmd+l"); text is sent as characters, whatever the layout.
    static let letters: [Character: CGKeyCode] = [
        "a": 0, "s": 1, "d": 2, "f": 3, "h": 4, "g": 5, "z": 6, "x": 7, "c": 8, "v": 9, "b": 11, "q": 12, "w": 13,
        "e": 14, "r": 15,
        "y": 16, "t": 17, "1": 18, "2": 19, "3": 20, "4": 21, "6": 22, "5": 23, "=": 24, "9": 25, "7": 26, "-": 27,
        "8": 28, "0": 29,
        "]": 30, "o": 31, "u": 32, "[": 33, "i": 34, "p": 35, "l": 37, "j": 38, "k": 40, ";": 41, ",": 43, "/": 44,
        "n": 45, "m": 46,
        ".": 47
    ]

    /// Types `text` as characters.
    static func type(_ text: String, pid: pid_t) {
        for character in text {
            let units = Array(String(character).utf16)
            for down in [true, false] {
                let event = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: down)
                event?.keyboardSetUnicodeString(stringLength: units.count, unicodeString: units)
                event?.postToPid(pid)
            }
            usleep(8_000)
        }
    }

    /// A chord: "cmd+shift+t", "return", "esc".
    static func chord(_ text: String, pid: pid_t) -> Bool {
        var flags: CGEventFlags = []
        var code: CGKeyCode?
        for part in text.lowercased().split(separator: "+") {
            switch part {
                case "cmd", "command": flags.insert(.maskCommand)
                case "shift": flags.insert(.maskShift)
                case "opt", "option", "alt": flags.insert(.maskAlternate)
                case "ctrl", "control": flags.insert(.maskControl)
                default: code = named[String(part)] ?? (part.count == 1 ? part.first.flatMap { letters[$0] } : nil)
            }
        }
        guard let code else { return false }
        for down in [true, false] {
            let event = CGEvent(keyboardEventSource: nil, virtualKey: code, keyDown: down)
            event?.flags = flags
            event?.postToPid(pid)
            usleep(20_000)
        }
        return true
    }
}
