package import AppKit

/// When a pane's view takes the keyboard on an update (its pane is the focused one): not from what is being typed into
/// elsewhere in the window, a row being renamed, the address field, the command bar (a rename lost its field when the
/// page loaded again). Those give it back themselves when they are done.
@MainActor
package enum PaneKeyboard {
    package static func takes(from responder: NSResponder?, into pane: NSView) -> Bool {
        if let view = responder as? NSView, view === pane || view.isDescendant(of: pane) { return false }
        if let editor = responder as? NSTextView, editor.isFieldEditor { return false }
        if responder is NSTextField { return false }
        return true
    }
}
