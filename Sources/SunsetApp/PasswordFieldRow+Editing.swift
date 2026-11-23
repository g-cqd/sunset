import SunsetCredentials
import SunsetShell
import SwiftUI

/// A field's row while its entry is edited: its name, its value (a secret one masked until its eye is pressed), and its
/// menu: generate, set up a code, secret or not, its kind, remove (n101–n104).
extension PasswordFieldRow {
    var edited: some View {
        HStack(spacing: Design.Space.s) {
            // Its name, renamed in place (n104).
            TextField("Name", text: name)
                .textFieldStyle(.plain)
                .foregroundStyle(.secondary)
                .frame(width: Self.nameWidth, alignment: .leading)
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
                Toggle("Secret", isOn: Binding(get: { field.isSecret }, set: edits.markSecret))
                Picker("Kind", selection: Binding(get: { field.kind }, set: edits.setKind)) {
                    ForEach(EntryDraft.addable, id: \.name) { Text($0.name).tag($0.kind) }
                    if !EntryDraft.addable.contains(where: { $0.kind == field.kind }) {
                        Text("As Made").tag(field.kind)
                    }
                }
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

    private var name: Binding<String> {
        Binding(get: { field.name }, set: edits.rename)
    }

    /// The name's column, as wide as a form's labels.
    private static let nameWidth = 110.0
}
