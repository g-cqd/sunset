package import AppKit
import SunsetCore
import SunsetShellModel

extension TerminalNSView {
    package override func keyDown(with event: NSEvent) {
        stopGliding()
        if let press = KeyboardMapping.press(for: event, optionAsMeta: optionAsMeta) {
            if scrollsHistory(press) { return }
            model.send(.key(press))
        } else {
            // Text: the input system composes dead keys and input methods, and calls `insertText`.
            interpretKeyEvents([event])
        }
    }

    /// ⌘= and ⌘⇧= (the two ways of typing ⌘+ on most keyboards) make the font bigger. The menu item is ⌘+, which AppKit does not always match against
    /// ⌘=, so the view takes the chord first.
    package override func performKeyEquivalent(with event: NSEvent) -> Bool {
        let flags = event.modifierFlags.intersection([.command, .option, .control])
        guard flags == .command, event.charactersIgnoringModifiers == "=" || event.charactersIgnoringModifiers == "+"
        else {
            return super.performKeyEquivalent(with: event)
        }
        model.onZoomRequest(1)
        return true
    }

    /// A copied file pastes as its path, as a dropped one does (`FileDrop.pasted`); anything else as its text.
    @objc package func paste(_ sender: Any?) {
        let board = NSPasteboard.general
        let files =
            board.readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) as? [URL] ?? []
        guard let text = FileDrop.pasted(files: files.map(\.path), text: board.string(forType: .string)) else { return }
        model.paste(text)
    }

    /// Shift with Page Up, Page Down, Home or End moves through the history instead of reaching the program (as in other terminals).
    private func scrollsHistory(_ press: KeyPress) -> Bool {
        guard press.modifiers == .shift else { return false }
        switch press.code {
            case .pageUp: model.scroll(byPages: 1)
            case .pageDown: model.scroll(byPages: -1)
            case .home: model.scroll(byLines: Int.max / 2)
            case .end: model.scrollToLive()
            default: return false
        }
        return true
    }
}
