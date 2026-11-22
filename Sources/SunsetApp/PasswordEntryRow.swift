import SunsetAppCore
import SunsetCredentials
import SunsetShell
import SwiftUI

/// An entry of the vault in the Passwords section: its template's symbol, its title and what names it (a login's
/// username, else its template). Open, its fields: a concealed one as dots until revealed, each copied with a click
/// (a concealed one marked so, for clipboard managers to leave it out).
struct PasswordEntryRow: View {
    let entry: VaultEntry
    let isOpen: Bool
    let model: PasswordsModel
    let toggle: () -> Void
    @State private var revealed: Set<EntryField.ID> = []

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
            if isOpen { fields }
        }
        .padding(.vertical, Design.Space.xs)
        .contextMenu {
            Button("Delete Entry", role: .destructive) { try? model.remove(entry.id) }
        }
    }

    private var fields: some View {
        ForEach(entry.sections.flatMap(\.fields).filter { !$0.value.isEmpty }) { field in
            HStack(spacing: Design.Space.s) {
                Text(field.name).font(Design.Text.detail).foregroundStyle(.secondary)
                Spacer(minLength: 0)
                Text(
                    field.kind.isConcealed && !revealed.contains(field.id)
                        ? "\u{2022}\u{2022}\u{2022}\u{2022}\u{2022}\u{2022}" : field.value
                )
                .font(Design.Text.detail.monospaced())
                .lineLimit(1)
                if field.kind.isConcealed {
                    SidebarIconButton(symbol: revealed.contains(field.id) ? "eye.slash" : "eye", help: "Show") {
                        if revealed.contains(field.id) { revealed.remove(field.id) } else { revealed.insert(field.id) }
                    }
                }
                SidebarIconButton(symbol: "doc.on.doc", help: "Copy \(field.name)") {
                    Feedback.give(
                        Clipboard.copy(field.value, concealed: field.kind.isConcealed, what: "\(field.name) copied")
                    )
                }
            }
            .padding(.leading, Design.Size.glyphFrame + Design.Space.s)
        }
    }
}
