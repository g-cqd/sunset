import SunsetAppCore
import SunsetCredentials
import SunsetShell
import SwiftUI

/// An entry of the vault in the Passwords section: its template's symbol, its title and what names it (a login's
/// username, else its template). Open, it is edited in place (`PasswordEntryEditor`).
struct PasswordEntryRow: View {
    let entry: VaultEntry
    let isOpen: Bool
    let model: PasswordsModel
    let toggle: () -> Void

    private var template: EntryTemplate? {
        EntryTemplate.shipped.first { $0.id == entry.template }
    }

    /// A login's username, else its template's name.
    private var subtitle: String {
        guard let user = entry.field(named: "Username")?.value, !user.isEmpty else { return template?.name ?? "Entry" }
        return user
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Design.Space.xs) {
            Button(action: toggle) {
                HStack(spacing: Design.Space.s) {
                    Image(systemName: template?.symbol ?? "lock").frame(width: Design.Size.glyphFrame)
                    VStack(alignment: .leading, spacing: Design.Space.hair) {
                        Text(entry.title.isEmpty ? "Untitled" : entry.title).lineLimit(1)
                        Text(subtitle)
                            .font(Design.Text.detail).foregroundStyle(.secondary).lineLimit(1)
                    }
                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            if isOpen { PasswordEntryEditor(entry: entry, model: model) }
        }
        .padding(.vertical, Design.Space.xs)
        .contextMenu {
            Button("Delete Entry", role: .destructive) { try? model.remove(entry.id) }
        }
    }
}
