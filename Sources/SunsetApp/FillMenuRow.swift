import SunsetShell
import SwiftUI

/// A row of the filling panel, drawn as a menu item: a symbol, a title and a detail; highlighted under the pointer
/// (the accent's fill, white text and glyph) with continuous corner radius concentric with the outer panel.
struct FillMenuRow: View {
    let title: String
    let detail: String
    /// The detail in a monospaced face (a password shown).
    var monospaced = false
    /// What it fills: a key for a password, a card for a card, a lock when unlocking.
    var symbol = "key.fill"
    let choose: () -> Void
    @State private var hovered = false

    /// A menu item's highlight corner, concentric inside the panel's `inset`: panel corner = `corner + inset` (12 pt).
    static let corner = 6.0
    static let inset = 6.0
    static let panelRadius = Design.Radius.container(holding: corner, inset: inset)

    var body: some View {
        Button(action: choose) {
            HStack(spacing: Design.Space.s) {
                Image(systemName: symbol)
                    .foregroundStyle(ink(secondary: true))
                    .frame(width: Design.Size.glyphFrame)
                VStack(alignment: .leading, spacing: Design.Space.hair) {
                    Text(title).lineLimit(1)
                    if !detail.isEmpty {
                        Text(detail)
                            .font(monospaced ? Design.Text.detail.monospaced() : Design.Text.detail)
                            .foregroundStyle(ink(secondary: true))
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }
                Spacer(minLength: 0)
            }
            .foregroundStyle(ink(secondary: false))
            .padding(.horizontal, Design.Space.s)
            .padding(.vertical, Design.Space.xs + Design.Space.hair)
            .background(
                Color.accentColor.opacity(hovered ? 1 : 0),
                in: RoundedRectangle(cornerRadius: Self.corner, style: .continuous)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovered = $0 }
        .accessibilityLabel(detail.isEmpty ? title : "\(title), \(detail)")
    }

    private func ink(secondary: Bool) -> AnyShapeStyle {
        guard hovered else { return secondary ? AnyShapeStyle(.secondary) : AnyShapeStyle(.primary) }
        return AnyShapeStyle(.white.opacity(secondary ? Design.Fill.inkSecondary : 1))
    }
}
