import SunsetCredentials
import SunsetShell
import SwiftUI

/// One field of an entry on its page: its name, its value as wide as the page (a secret one as dots, never its
/// characters), copy, and a menu to generate a password into it or remove it; the problem with its value under it.
struct PasswordFieldRow: View {
    let field: EntryField
    let problem: String?
    @Binding var value: String
    let generate: () -> Void
    let remove: () -> Void

    var body: some View {
        LabeledContent {
            VStack(alignment: .leading, spacing: Design.Space.hair) {
                HStack(spacing: Design.Space.s) {
                    input.textFieldStyle(.roundedBorder).labelsHidden()
                    Button("Copy", systemImage: "doc.on.doc") {
                        Feedback.give(
                            Clipboard.copy(value, concealed: field.kind.isConcealed, what: "\(field.name) copied")
                        )
                    }
                    .labelStyle(.iconOnly)
                    .buttonStyle(.borderless)
                    Menu("\(field.name) Actions", systemImage: "ellipsis.circle") {
                        if field.kind == .concealed { Button("Generate Password", action: generate) }
                        Button("Remove Field", role: .destructive, action: remove)
                    }
                    .labelStyle(.iconOnly)
                    .menuStyle(.button)
                    .buttonStyle(.borderless)
                    .menuIndicator(.hidden)
                    .fixedSize()
                }
                if let problem {
                    Text(problem).font(Design.Text.detail).foregroundStyle(.orange)
                }
            }
        } label: {
            Text(field.name).foregroundStyle(.secondary)
        }
    }

    @ViewBuilder private var input: some View {
        if field.kind.isConcealed {
            SecureField(field.name, text: $value).font(Design.Text.body.monospaced())
        } else {
            TextField(field.name, text: $value, axis: field.kind == .multiline ? .vertical : .horizontal)
        }
    }
}
