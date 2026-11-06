import AppKit

/// The text input client: what lets dead keys (Option-E, then E) and input methods compose before the characters reach the program. The marked (not yet
/// committed) text is held but not drawn yet.
extension TerminalNSView: @preconcurrency NSTextInputClient {
    func insertText(_ string: Any, replacementRange: NSRange) {
        markedText = NSAttributedString()
        let text = (string as? NSAttributedString)?.string ?? (string as? String) ?? ""
        if !text.isEmpty { model.send(.text(text)) }
    }

    func setMarkedText(_ string: Any, selectedRange: NSRange, replacementRange: NSRange) {
        markedText = (string as? NSAttributedString) ?? NSAttributedString(string: (string as? String) ?? "")
    }

    func unmarkText() { markedText = NSAttributedString() }
    func hasMarkedText() -> Bool { markedText.length > 0 }
    func markedRange() -> NSRange {
        markedText.length > 0
            ? NSRange(location: 0, length: markedText.length) : NSRange(location: NSNotFound, length: 0)
    }
    func selectedRange() -> NSRange { NSRange(location: NSNotFound, length: 0) }
    func validAttributedString(for string: NSAttributedString) -> NSAttributedString { string }
    func validAttributesForMarkedText() -> [NSAttributedString.Key] { [] }
    func attributedSubstring(forProposedRange range: NSRange, actualRange: NSRangePointer?) -> NSAttributedString? {
        nil
    }
    func characterIndex(for point: NSPoint) -> Int { 0 }

    /// Where the input method puts its candidate window: near the top left of the view (the cursor's cell is not tracked yet).
    func firstRect(forCharacterRange range: NSRange, actualRange: NSRangePointer?) -> NSRect {
        guard let window else { return .zero }
        return window.convertToScreen(convert(NSRect(x: 0, y: 0, width: 1, height: 16), to: nil))
    }

    override func doCommand(by selector: Selector) {
        // Commands the text system derives from keys (deleteBackward and the like) were already sent as named keys.
    }
}
