import SunsetCredentials
import SunsetRuntime
import SunsetShell
import SwiftUI

/// One field of an entry on its page, a row of the form: its name, then its value. Read, the value (a secret one as dots,
/// never its characters), copied by a click on the row or its button. Edited, a field of the form (a secret one a secure
/// field), its menu to generate a password into it or remove it. A problem with its value under it.
struct PasswordFieldRow: View {
    let field: EntryField
    let editing: Bool
    let problem: String?
    @Binding var value: String
    let generate: () -> Void
    let remove: () -> Void
    @State private var hovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: Design.Space.hair) {
            if editing { edited } else { read }
            if let problem {
                Text(problem).font(Design.Text.detail).foregroundStyle(.orange)
            }
        }
    }

    private var read: some View {
        LabeledContent(field.name) {
            HStack(spacing: Design.Space.s) {
                if field.kind == .oneTimeCode {
                    OneTimeCodeValue(field: OneTimeCodeField(value))
                } else {
                    Text(field.kind.isConcealed ? Self.dots : value)
                        .lineLimit(field.kind == .multiline ? nil : 1)
                        .truncationMode(.middle)
                        .foregroundStyle(.primary)
                }
                Image(systemName: "doc.on.doc")
                    .foregroundStyle(.secondary)
                    .opacity(hovered ? 1 : 0)
                    .accessibilityHidden(true)
            }
        }
        .contentShape(Rectangle())
        .onHover { hovered = $0 }
        .onTapGesture(perform: copy)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityAction(named: "Copy \(field.name)", copy)
        .contextMenu { Button("Copy \(field.name)", action: copy) }
    }

    private var edited: some View {
        HStack(spacing: Design.Space.s) {
            Group {
                if field.kind.isConcealed {
                    SecureField(field.name, text: $value, prompt: Text(prompt))
                } else {
                    TextField(field.name, text: $value, prompt: Text(prompt), axis: axis)
                }
            }
            Menu {
                if field.kind == .concealed { Button("Generate Password", action: generate) }
                if field.kind == .oneTimeCode {
                    Button("Read from QR Code Image\u{2026}") { QRCodeImagePicker.read { value = $0 } }
                }
                Button("Remove Field", role: .destructive, action: remove)
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            .menuStyle(.button)
            .buttonStyle(.borderless)
            .menuIndicator(.hidden)
            .fixedSize()
            .tint(.secondary)
            .accessibilityLabel("\(field.name) Actions")
        }
    }

    /// "Required" for a field that must be filled, else "Optional".
    private var prompt: String {
        field.constraints.contains(.required) ? "Required" : "Optional"
    }

    private var axis: Axis {
        field.kind == .multiline ? .vertical : .horizontal
    }

    /// The value; a One-Time Code field's code now, never its secret.
    private func copy() {
        if field.kind == .oneTimeCode {
            guard let code = OneTimeCodeField(value)?.code(at: Runtime.live.now()) else { return }
            Feedback.give(Clipboard.copy(code, concealed: true, what: "Code copied"))
            return
        }
        Feedback.give(Clipboard.copy(value, concealed: field.kind.isConcealed, what: "\(field.name) copied"))
    }

    /// A secret's stand-in: always as long, whatever its length.
    private static let dots = String(repeating: "\u{2022}", count: 10)
}
