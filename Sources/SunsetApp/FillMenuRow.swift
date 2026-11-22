import SunsetShell
import SwiftUI

/// A row of the filling popovers, drawn as a macOS menu's item: a key, a title and a detail; highlighted under the pointer
/// (the accent's fill, white text and glyph). Nothing happens until it is clicked.
struct FillMenuRow: View {
    let title: String
    let detail: String
    /// The detail in a monospaced face (a password shown).
    var monospaced = false
    /// What it fills: a key for a password, a card for a card.
    var symbol = "key.fill"
    let choose: () -> Void
    @State private var hovered = false

    var body: some View {
        Button(action: choose) {
            HStack(spacing: Design.Space.s) {
                Image(systemName: symbol)
                    .foregroundStyle(ink(secondary: true))
                    .frame(width: Design.Size.glyphFrame)
                VStack(alignment: .leading, spacing: Design.Space.hair) {
                    Text(title).lineLimit(1)
                    Text(detail)
                        .font(monospaced ? Design.Text.detail.monospaced() : Design.Text.detail)
                        .foregroundStyle(ink(secondary: true))
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                Spacer(minLength: 0)
            }
            .foregroundStyle(ink(secondary: false))
            .padding(.horizontal, Design.Space.s)
            .padding(.vertical, Design.Space.xs)
            .background(
                Color.accentColor.opacity(hovered ? 1 : 0),
                in: RoundedRectangle(cornerRadius: Self.corner, style: .continuous)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovered = $0 }
        .accessibilityLabel("\(title), \(detail)")
    }

    private func ink(secondary: Bool) -> AnyShapeStyle {
        guard hovered else { return secondary ? AnyShapeStyle(.secondary) : AnyShapeStyle(.primary) }
        return AnyShapeStyle(.white.opacity(secondary ? Design.Fill.inkSecondary : 1))
    }

    /// A menu item's highlight corner.
    private static let corner = 5.0
}
