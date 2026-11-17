import SwiftUI

/// What a row of a choice list shows: its glyph, title and subtitle, and its accessory on the right.
struct ChoiceRowView: View {
    let row: ChoiceRow
    let selected: Bool
    @Environment(\.accent) private var accent
    @State private var width = 0.0

    /// What a row shows by its width (roadmap 0036 B): in a narrow one (the sidebar's) the title has the room first, the
    /// subtitle goes, then the accessory.
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
                    .foregroundStyle(
                        selected
                            ? AnyShapeStyle(accent.ink.opacity(Design.Fill.inkSecondary)) : AnyShapeStyle(.secondary)
                    )
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Spacer(minLength: Design.Space.m)
            if let accessory = row.accessory, parts.accessory {
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
        .onGeometryChange(for: Double.self, of: { Double($0.size.width) }) { width = $0 }
        .contentShape(.rect)
    }
}
