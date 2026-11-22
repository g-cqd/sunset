import SunsetCredentials
import SunsetShell
import SwiftUI

/// One field of an entry being edited: its name, its value (a concealed one as a secure field until shown), copy, and a
/// menu to generate a password into it or remove it; the problem with its value under it.
struct PasswordFieldRow: View {
    let field: EntryField
    let problem: String?
    let isRevealed: Bool
    @Binding var value: String
    let reveal: () -> Void
    let generate: () -> Void
    let remove: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Design.Space.hair) {
            Text(field.name).font(Design.Text.detail).foregroundStyle(.secondary)
            HStack(spacing: Design.Space.xs) {
                Group {
                    if field.kind.isConcealed && !isRevealed {
                        SecureField(field.name, text: $value)
                    } else {
                        TextField(field.name, text: $value, axis: field.kind == .multiline ? .vertical : .horizontal)
                    }
                }
                .textFieldStyle(.roundedBorder)
                .font(field.kind.isConcealed ? Design.Text.detail.monospaced() : Design.Text.detail)
                .labelsHidden()
                if field.kind.isConcealed {
                    SidebarIconButton(
                        symbol: isRevealed ? "eye.slash" : "eye",
                        help: isRevealed ? "Hide" : "Show",
                        action: reveal
                    )
                }
                SidebarIconButton(symbol: "doc.on.doc", help: "Copy \(field.name)") {
                    Feedback.give(
                        Clipboard.copy(value, concealed: field.kind.isConcealed, what: "\(field.name) copied")
                    )
                }
                Menu {
                    if field.kind == .concealed { Button("Generate Password", action: generate) }
                    Button("Remove Field", role: .destructive, action: remove)
                } label: {
                    Image(systemName: "ellipsis")
                }
                .menuStyle(.button)
                .buttonStyle(.plain)
                .menuIndicator(.hidden)
                .fixedSize()
                .accessibilityLabel("\(field.name) Actions")
            }
            if let problem {
                Text(problem).font(Design.Text.detail).foregroundStyle(.orange)
            }
        }
    }
}
