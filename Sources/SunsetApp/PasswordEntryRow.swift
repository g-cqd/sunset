import SunsetCredentials
import SunsetMetrics
import SunsetShell
import SwiftUI

/// An entry of the vault in the Passwords section: its template's symbol, its title and what names it (a login's
/// username, else its template). Chosen, it opens on the vault's page, wide enough to edit.
struct PasswordEntryRow: View {
    let entry: VaultEntry
    let isSelected: Bool
    let layout: LayoutMetrics
    let open: () -> Void
    let remove: () -> Void

    private var template: EntryTemplate? {
        EntryTemplate.shipped.first { $0.id == entry.template }
    }

    /// A login's username, else its template's name.
    private var subtitle: String {
        guard let user = entry.field(named: "Username")?.value, !user.isEmpty else { return template?.name ?? "Entry" }
        return user
    }

    var body: some View {
        Button(action: open) {
            HStack(spacing: Design.Space.s) {
                Image(systemName: template?.symbol ?? "lock").frame(width: Design.Size.glyphFrame)
                VStack(alignment: .leading, spacing: Design.Space.hair) {
                    Text(entry.title.isEmpty ? "Untitled" : entry.title).lineLimit(1)
                    Text(subtitle).font(Design.Text.detail).foregroundStyle(.secondary).lineLimit(1)
                }
                Spacer(minLength: 0)
            }
            .padding(.vertical, Design.Space.xs)
            .padding(.horizontal, Design.Space.s)
            .background(
                RoundedRectangle(cornerRadius: Design.Radius.small(layout))
                    .fill(isSelected ? AnyShapeStyle(.selection) : AnyShapeStyle(.clear))
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button("Delete Entry", role: .destructive, action: remove)
        }
    }
}
