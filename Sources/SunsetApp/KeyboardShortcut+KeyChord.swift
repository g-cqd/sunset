import SunsetShellModel
import SwiftUI

extension KeyboardShortcut {
    init(_ chord: KeyChord) {
        let key: KeyEquivalent =
            switch chord.key {
                case .character(let character): KeyEquivalent(character)
                case .up: .upArrow
                case .down: .downArrow
                case .left: .leftArrow
                case .right: .rightArrow
            }
        var modifiers: EventModifiers = []
        if chord.modifiers.contains(.command) { modifiers.insert(.command) }
        if chord.modifiers.contains(.shift) { modifiers.insert(.shift) }
        if chord.modifiers.contains(.option) { modifiers.insert(.option) }
        if chord.modifiers.contains(.control) { modifiers.insert(.control) }
        self.init(key, modifiers: modifiers)
    }
}
