import SwiftUI

/// What a row of a choice list shows: its glyph, title and subtitle, and its accessory on the right.
struct ChoiceRowView: View {
    let row: ChoiceRow
    let selected: Bool
    /// From the row's fill to its glyph: on the field's line (`CommandBarGrid`).
    var padding = Design.Space.l
    @Environment(\.accent) private var accent
    @State private var width = 0.0

    /// What a row shows by its width: in a narrow one (the sidebar's) the title has the room first, the subtitle goes,
    /// then the accessory.
    struct Parts: Equatable {
        static let subtitleWidth = 400.0
        static let accessoryWidth = 300.0

        let subtitle: Bool
        let accessory: Bool
        /// Cut at the end in a narrow row, where the title's start says what it is ("swift concurrency sen…"); in the
        /// middle in a wide one, where an address keeps its host and its end.
        let cutsAtEnd: Bool

        init(width: Double) {
            subtitle = width >= Self.subtitleWidth
            accessory = width >= Self.accessoryWidth
            cutsAtEnd = !accessory
        }
    }

    var body: some View {
        // Unmeasured yet: everything, as before.
        let parts = Parts(width: width == 0 ? .infinity : width)
        return HStack(spacing: GlyphSpacing.toText) {
            PaneGlyphView(glyph: row.glyph).frame(width: Design.Size.glyphFrame)
            Text(row.title).lineLimit(1).truncationMode(parts.cutsAtEnd ? .tail : .middle)
            if let subtitle = row.subtitle, parts.subtitle {
                Text(subtitle)
                    .font(Design.Text.detail)
                    .foregroundStyle(detail(Design.Fill.inkSecondary))
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Spacer(minLength: Design.Space.m)
            if let accessory = row.accessory, parts.accessory {
                Text(accessory)
                    .font(Design.Text.detail)
                    .foregroundStyle(detail(Design.Fill.accentPressed))
                    .padding(.horizontal, Design.Space.s)
                    .padding(.vertical, Design.Space.hair)
                    .background(Capsule().fill(Color.primary.opacity(selected ? 0 : Design.Fill.hover)))
            }
        }
        .foregroundStyle(selected ? AnyShapeStyle(accent.ink) : AnyShapeStyle(.primary))
        .padding(.leading, padding)
        .padding(.trailing, Design.Space.l)
        .frame(height: ChoiceList.rowHeight - Design.Space.hair)
        .frame(maxWidth: .infinity, alignment: .leading)
        .onGeometryChange(for: Double.self, of: { Double($0.size.width) }) { width = $0 }
        .contentShape(.rect)
    }

    /// A detail's colour: the accent's ink at `opacity` on the selected row, else secondary.
    private func detail(_ opacity: Double) -> AnyShapeStyle {
        selected ? AnyShapeStyle(accent.ink.opacity(opacity)) : AnyShapeStyle(.secondary)
    }
}
