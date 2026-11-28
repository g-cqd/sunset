import SunsetCredentials
import SunsetShell
import SwiftUI

/// A field's row while its entry is edited: its name and its value (a secret one masked until its eye is pressed), and its
/// menu: generate, set up a code, Edit Field (its name, kind and secrecy, in a sheet: t334), remove.
extension PasswordFieldRow {
    /// Its name typed in place (the owner, 2026-11-28: not in a sheet), its kind shown when it has none; a handle to drag
    /// it to another place.
    var edited: some View {
        LabeledContent {
            editedValue
        } label: {
            HStack(spacing: Design.Space.s) {
                Image(systemName: "line.3.horizontal")
                    .foregroundStyle(.tertiary)
                    .draggable(field.id.uuidString)
                    .accessibilityLabel("Move \(shownName)")
                TextField("Name", text: name, prompt: Text(kindName))
                    .labelsHidden()
                    .textFieldStyle(.plain)
                    .fixedSize()
            }
        }
        .dropDestination(for: String.self) { ids, _ in
            guard let id = ids.first.flatMap(UUID.init(uuidString:)) else { return false }
            moveHere(id)
            return true
        }
        .sheet(isPresented: $editingField) {
            FieldEditSheet(field: field, save: edits.apply)
        }
    }

    /// The name as typed: kept as it is, empty too (the kind is then shown).
    private var name: Binding<String> {
        Binding(
            get: { field.name },
            set: { edits.apply(FieldChange(name: $0, kind: field.kind, secret: field.isSecret)) }
        )
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
            // Its name is the row's own, typed in place: not said again beside the value.
            .labelsHidden()
            .font(field.isSecret ? Design.Text.body.monospaced() : Design.Text.body)
            if field.isSecret { revealButton }
            if let history = field.history, !history.isEmpty { historyButton(history) }
            Menu {
                if field.kind == .concealed {
                    Button("Generate Password", action: generate)
                    Button("Generate Passphrase", action: generatePassphrase)
                }
                if field.kind == .oneTimeCode {
                    Button("Paste QR Code") { pasteCode() }
                    Button("Read from QR Code Image\u{2026}") { QRCodeImagePicker.read(into: readCode) }
                }
                if let history = field.history, !history.isEmpty {
                    Divider()
                    Button("Password History (\(history.count))\u{2026}") { showingHistory = true }
                }
                Divider()
                Button("Kind and Secrecy\u{2026}") { editingField = true }
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

    /// Shows prior values recorded when this secret field changed (roadmap 0092 D).
    func historyButton(_ items: [FieldHistoryItem]) -> some View {
        RowGlyphButton(symbol: "clock.arrow.circlepath", help: "History (\(items.count))") {
            showingHistory = true
        }
        .accessibilityLabel("\(field.name) History")
        .popover(isPresented: $showingHistory) {
            FieldHistoryPopover(
                fieldName: field.name,
                items: items,
                onRestore: editing ? { value = $0 } : nil
            )
        }
    }
}
