import AppKit
import Testing

@testable import SunsetShell
@testable import SunsetShellModel

/// A tab being renamed lost its field when its page loaded again (going back where it was kept): the page's host took
/// the keyboard back at each update. A pane takes the keyboard from nothing being typed into.
@MainActor @Suite("A pane taking the keyboard")
struct PaneKeyboardTests {
    @Test func `not from a field being edited (its field editor), nor from a text field; from anything else`() {
        let pane = NSView()
        let editor = NSTextView()
        editor.isFieldEditor = true
        #expect(!PaneKeyboard.takes(from: editor, into: pane))
        #expect(!PaneKeyboard.takes(from: NSTextField(), into: pane))
        #expect(PaneKeyboard.takes(from: nil, into: pane))
        #expect(PaneKeyboard.takes(from: NSView(), into: pane), "another pane's view")
        #expect(
            PaneKeyboard.takes(from: NSTextView(), into: pane),
            "a text view that is not a field's editor (a page, a document)"
        )
        let inside = NSView()
        pane.addSubview(inside)
        #expect(!PaneKeyboard.takes(from: inside, into: pane), "it has it already")
    }
}
