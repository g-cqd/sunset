import AppKit
import SwiftUI

/// `AddressNSField` in SwiftUI. `focusNow` set to true gives it the keyboard (and is set back to false).
struct AddressTextField: NSViewRepresentable {
    let host: String
    let address: String
    @Binding var focusNow: Bool
    let onSubmit: (String) -> Void
    let onCancel: () -> Void
    let onEditing: (Bool) -> Void

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeNSView(context: Context) -> AddressNSField {
        let field = AddressNSField()
        field.isBordered = false
        field.drawsBackground = false
        field.focusRingType = .none
        field.font = .systemFont(ofSize: NSFont.systemFontSize)
        field.lineBreakMode = .byTruncatingMiddle
        field.cell?.usesSingleLineMode = true
        field.placeholderString = "Address"
        field.delegate = context.coordinator
        return field
    }

    func updateNSView(_ field: AddressNSField, context: Context) {
        field.address = address
        field.host = host
        field.onSubmit = onSubmit
        field.onCancel = onCancel
        field.onEditing = onEditing
        context.coordinator.field = field
        if focusNow {
            Task { @MainActor in
                focusNow = false
                field.beginTyping()
            }
        }
    }

    @MainActor final class Coordinator: NSObject, NSTextFieldDelegate {
        weak var field: AddressNSField?

        func control(_ control: NSControl, textView: NSTextView, doCommandBy selector: Selector) -> Bool {
            guard let field else { return false }
            switch selector {
                case #selector(NSResponder.insertNewline(_:)):
                    let typed = field.stringValue
                    field.endTyping()
                    field.onSubmit(typed)
                    return true
                case #selector(NSResponder.cancelOperation(_:)):
                    field.endTyping()
                    field.onCancel()
                    return true
                default:
                    return false
            }
        }

        func controlTextDidEndEditing(_ notification: Notification) { field?.endTyping() }
    }
}
