import AppKit
import SunsetCore

extension TerminalNSView {
    override func keyDown(with event: NSEvent) {
        if let press = KeyboardMapping.press(for: event, optionAsMeta: optionAsMeta) {
            if scrollsHistory(press) { return }
            model.send(.key(press))
        } else {
            // Text: the input system composes dead keys and input methods, and calls `insertText`.
            interpretKeyEvents([event])
        }
    }

    @objc func paste(_ sender: Any?) {
        guard let text = NSPasteboard.general.string(forType: .string) else { return }
        model.send(.paste(text))
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
