package import AppKit

/// Copy, Paste and Select All of the Edit menu, answered as a responder: the menu's own items find whichever view has the keyboard, a terminal or the
/// text view of a note, so nothing in the menu is made for terminals only. (Paste is in `TerminalNSView+Keys`.)
extension TerminalNSView: NSMenuItemValidation {
    @objc package func copy(_ sender: Any?) {
        guard let text = model.selectedText else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }

    package override func selectAll(_ sender: Any?) { model.selectAll() }

    package func validateMenuItem(_ item: NSMenuItem) -> Bool {
        switch item.action {
            case #selector(copy(_:)): model.hasSelection
            case #selector(paste(_:)): NSPasteboard.general.string(forType: .string) != nil
            default: true
        }
    }
}
