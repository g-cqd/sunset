import SwiftUI

/// What a row of a choice list shows: its glyph, title and subtitle, and its accessory on the right.
struct ChoiceRowView: View {
    let row: ChoiceRow
    let selected: Bool

    var body: some View {
        HStack(spacing: 8) {
            PaneGlyphView(glyph: row.glyph).frame(width: 18)
            Text(row.title).lineLimit(1).truncationMode(.middle)
            if let subtitle = row.subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(selected ? AnyShapeStyle(.white.opacity(0.75)) : AnyShapeStyle(.secondary))
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Spacer(minLength: 8)
            if let accessory = row.accessory {
                Text(accessory)
                    .font(.caption)
                    .foregroundStyle(selected ? AnyShapeStyle(.white.opacity(0.8)) : AnyShapeStyle(.secondary))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color.primary.opacity(selected ? 0 : 0.07)))
            }
        }
        .foregroundStyle(selected ? AnyShapeStyle(.white) : AnyShapeStyle(.primary))
        .padding(.horizontal, 10)
        .frame(height: ChoiceList.rowHeight - 2)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(.rect)
    }
}
