import AppKit

/// The text field of an address: it shows the host until clicked, then the whole address, selected, whatever was clicked; Return hands over what was
/// typed, Escape gives up. Either way the host comes back. It takes the keyboard only when clicked or asked (`beginTyping`): AppKit would otherwise
/// give a new window's first field the keyboard, away from the page or the terminal.
final class AddressNSField: NSTextField {
    /// What is shown when not typed in, and what typing starts from.
    var host = "" {
        didSet { if !isEditing { stringValue = host } }
    }
    var address = ""
    var onSubmit: (String) -> Void = { _ in }
    var onCancel: () -> Void = {}
    var onEditing: (Bool) -> Void = { _ in }
    private var typing = false

    var isEditing: Bool { currentEditor() != nil }

    override var acceptsFirstResponder: Bool { typing }

    /// The first click selects the whole address instead of placing the caret (AppKit's field editor would track the click).
    override func mouseDown(with event: NSEvent) {
        if isEditing { super.mouseDown(with: event) } else { beginTyping() }
    }

    /// Makes the field the one that has the keyboard, with the whole address selected.
    func beginTyping() {
        typing = true
        guard let window, window.makeFirstResponder(self) else {
            typing = false
            return
        }
        stringValue = address
        currentEditor()?.selectAll(nil)
        onEditing(true)
    }

    /// Confirm through accessibility (VoiceOver, or a test driving Sunset in the background): what the field holds is opened, as Return does.
    override func accessibilityPerformConfirm() -> Bool {
        let typed = stringValue
        endTyping()
        onSubmit(typed)
        return true
    }

    func endTyping() {
        typing = false
        stringValue = host
        onEditing(false)
    }
}
