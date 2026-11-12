import SwiftUI

/// What a row of a choice list shows: its glyph, title and subtitle, and its accessory on the right.
struct ChoiceRowView: View {
    let row: ChoiceRow
    let selected: Bool
    @Environment(\.accent) private var accent

    var body: some View {
        HStack(spacing: GlyphSpacing.toText) {
            PaneGlyphView(glyph: row.glyph).frame(width: Design.Size.glyphFrame)
            Text(row.title).lineLimit(1).truncationMode(.middle)
            if let subtitle = row.subtitle {
                Text(subtitle)
                    .font(Design.Text.detail)
                    .foregroundStyle(
                        selected
                            ? AnyShapeStyle(accent.ink.opacity(Design.Fill.inkSecondary)) : AnyShapeStyle(.secondary)
                    )
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Spacer(minLength: Design.Space.m)
            if let accessory = row.accessory {
                Text(accessory)
                    .font(Design.Text.detail)
                    .foregroundStyle(
                        selected
                            ? AnyShapeStyle(accent.ink.opacity(Design.Fill.accentPressed)) : AnyShapeStyle(.secondary)
                    )
                    .padding(.horizontal, Design.Space.s)
                    .padding(.vertical, Design.Space.hair)
                    .background(Capsule().fill(Color.primary.opacity(selected ? 0 : Design.Fill.hover)))
            }
        }
        .foregroundStyle(selected ? AnyShapeStyle(accent.ink) : AnyShapeStyle(.primary))
        .padding(.horizontal, Design.Space.l)
        .frame(height: ChoiceList.rowHeight - Design.Space.hair)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(.rect)
    }
}
