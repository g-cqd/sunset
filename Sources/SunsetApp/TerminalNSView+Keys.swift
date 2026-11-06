import AppKit

extension TerminalNSView {
    override func keyDown(with event: NSEvent) {
        if let press = KeyboardMapping.press(for: event, optionAsMeta: optionAsMeta) {
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
}
