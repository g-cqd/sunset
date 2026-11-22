import SunsetCredentials
import SunsetMetrics
import SunsetShell
import SwiftUI

/// An entry in the Library's Passwords section, drawn as the Library's other rows (`LibraryRowFrame`): its template's
/// glyph, its title and what names it (a login's username, else its template). Chosen, it opens on the vault's page.
struct PasswordEntryRow: View {
    let entry: VaultEntry
    let isSelected: Bool
    let layout: LayoutMetrics
    let open: () -> Void
    let remove: () -> Void
    private static let lines = 2
    @State private var hovered = false

    var body: some View {
        HStack(spacing: GlyphSpacing.toText) {
            PaneGlyphView(glyph: .symbol(PasswordLook.symbol(entry)))
            VStack(alignment: .leading, spacing: Design.Space.hair) {
                Text(PasswordLook.title(entry)).lineLimit(1)
                Text(PasswordLook.subtitle(entry)).font(Design.Text.detail).foregroundStyle(.secondary).lineLimit(1)
            }
        }
        .modifier(LibraryRowFrame(layout: layout, lines: Self.lines, fill: fill, hovered: $hovered))
        .onTapGesture(perform: open)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
        .accessibilityAction { open() }
        .contextMenu {
            Button("Open", action: open)
            Divider()
            Button("Delete Entry", role: .destructive, action: remove)
        }
    }

    private var fill: Double {
        if isSelected { return hovered ? Design.Fill.selectedHover : Design.Fill.selected }
        return hovered ? Design.Fill.hover : 0
    }
}
