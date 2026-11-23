import SunsetCredentials
import SunsetShell
import SwiftUI

/// A field's row while its entry is edited: its name and its value (a secret one masked until its eye is pressed), and its
/// menu: generate, set up a code, Edit Field (its name, kind and secrecy, in a sheet: t334), remove.
extension PasswordFieldRow {
    var edited: some View {
        LabeledContent(field.name) {
            editedValue
        }
        .sheet(isPresented: $editingField) {
            FieldEditSheet(field: field, save: edits.apply)
        }
    }

    private var editedValue: some View {
        HStack(spacing: Design.Space.s) {
            Group {
                if field.isSecret && !revealed {
                    SecureField(field.name, text: $value, prompt: Text(prompt))
                } else {
                    TextField(field.name, text: $value, prompt: Text(prompt), axis: axis)
                }
            }
            .font(field.isSecret ? Design.Text.body.monospaced() : Design.Text.body)
            if field.isSecret { revealButton }
            Menu {
                if field.kind == .concealed { Button("Generate Password", action: generate) }
                if field.kind == .oneTimeCode {
                    Button("Paste QR Code") { pasteCode() }
                    Button("Read from QR Code Image\u{2026}") { QRCodeImagePicker.read(into: readCode) }
                }
                Divider()
                Button("Edit Field\u{2026}") { editingField = true }
                Divider()
                Button("Remove Field", role: .destructive, action: remove)
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            .menuStyle(.button)
            .buttonStyle(.quietGlyph)
            .menuIndicator(.hidden)
            .fixedSize()
            .tint(.secondary)
            .accessibilityLabel("\(field.name) Actions")
        }
    }

    /// Shows a secret in clear, or masks it again (n101).
    var revealButton: some View {
        RowGlyphButton(symbol: revealed ? "eye.slash" : "eye", help: revealed ? "Hide" : "Show") { revealed.toggle() }
            .accessibilityLabel(revealed ? "Hide \(field.name)" : "Show \(field.name)")
    }
}
