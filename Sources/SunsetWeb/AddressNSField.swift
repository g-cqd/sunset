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
        // Typed in, the text scrolls and is clipped, not truncated: a truncating cell's editor kept the end of a long address
        // (and the caret there) a couple of points past what it shows (the owner's note n10).
        typingLayout(true)
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
        typingLayout(false)
        stringValue = host
        onEditing(false)
    }

    /// Laid out narrower while typed in (its row's buttons, its sidebar's width), the field kept its editor at the width it
    /// began with: the editor scrolled to an end the field no longer showed, and the end of the address and the caret were
    /// hidden past the field's edge (the owner's note n10). The editor follows the field.
    override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        fitEditor()
    }

    override func layout() {
        super.layout()
        fitEditor()
    }

    private static let edge = 2.0

    private func fitEditor() {
        guard let editor = currentEditor() as? NSTextView, let clip = editor.superview, let cell else { return }
        // Its width only: the editor's height and line are AppKit's.
        // Inside the field's own edges, which clip what the editor draws past them (2 points each side).
        let drawn = cell.drawingRect(forBounds: bounds).insetBy(dx: Self.edge, dy: 0)
        let shown = CGRect(x: drawn.minX, y: clip.frame.minY, width: drawn.width, height: clip.frame.height)
        guard clip.frame != shown else { return }
        clip.frame = shown
        editor.scrollRangeToVisible(editor.selectedRange())
    }

    /// Scrolling and clipped while typed in; truncated in its middle when showing the host.
    private func typingLayout(_ typed: Bool) {
        cell?.isScrollable = typed
        cell?.lineBreakMode = typed ? .byClipping : .byTruncatingMiddle
        cell?.truncatesLastVisibleLine = !typed
    }
}
