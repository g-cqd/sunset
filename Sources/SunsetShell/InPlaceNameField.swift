import AppKit
import SwiftUI

/// A text field that takes the keyboard when it appears, from whatever had it (a terminal view keeps it otherwise: SwiftUI's focus does not reach past
/// AppKit's first responder). Return commits, Escape cancels, losing the keyboard commits.
struct InPlaceNameField: NSViewRepresentable {
    @Binding var text: String
    let commit: () -> Void
    let cancel: () -> Void

    func makeNSView(context: Context) -> NSTextField {
        let field = TakingField(string: text)
        field.isBordered = false
        field.drawsBackground = false
        field.focusRingType = .none
        field.font = .systemFont(ofSize: 12)
        field.delegate = context.coordinator
        return field
    }

    /// Takes the keyboard as soon as it is in a window, with its text selected.
    final class TakingField: NSTextField {
        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            guard let window else { return }
            Task { @MainActor in
                window.makeFirstResponder(self)
                self.currentEditor()?.selectAll(nil)
            }
        }
    }

    func updateNSView(_ field: NSTextField, context: Context) {
        context.coordinator.parent = self
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    @MainActor final class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: InPlaceNameField
        private var finished = false

        init(_ parent: InPlaceNameField) { self.parent = parent }

        func controlTextDidChange(_ note: Notification) {
            if let field = note.object as? NSTextField { parent.text = field.stringValue }
        }

        func control(_ control: NSControl, textView: NSTextView, doCommandBy selector: Selector) -> Bool {
            if selector == #selector(NSResponder.cancelOperation(_:)) {
                finish(parent.cancel)
                return true
            }
            if selector == #selector(NSResponder.insertNewline(_:)) {
                finish(parent.commit)
                return true
            }
            return false
        }

        func controlTextDidEndEditing(_ note: Notification) { finish(parent.commit) }

        private func finish(_ action: () -> Void) {
            guard !finished else { return }
            finished = true
            action()
        }
    }
}
