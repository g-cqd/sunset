import SunsetMetrics
import SunsetShell
import SwiftUI

/// A section or a topic in a list of the settings: a sidebar row (the tabs' height and corner), a section with its picture, a
/// topic under it indented to the section's title; the topic shown has the selected tab's fill.
struct SettingsListRow: View {
    let title: String
    /// A section's SF Symbol; nil for a topic.
    let symbol: String?
    let selected: Bool
    let layout: LayoutMetrics
    let action: () -> Void
    @State private var hovered = false

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: layout.tabRadius, style: .continuous)
        Button(action: action) {
            HStack(spacing: GlyphSpacing.toText) {
                if let symbol {
                    PaneGlyphView(glyph: .symbol(symbol))
                } else {
                    Color.clear.frame(width: Design.Size.glyphFrame, height: Design.Size.glyphFrame)
                }
                Text(title).lineLimit(1).foregroundStyle(symbol == nil && !selected ? .secondary : .primary)
                Spacer(minLength: 0)
            }
            .padding(.leading, layout.tabPaddingLeading)
            .padding(.trailing, layout.tabPaddingTrailing)
            .frame(
                height: Design.oneLineHeight(layout, height: symbol == nil ? Design.Size.topicRow : Design.Size.tabRow)
            )
            .background(shape.fill(Color.primary.opacity(fill)))
            .contentShape(shape)
        }
        .buttonStyle(.plain)
        .onHover { hovered = $0 }
        .animation(layout.smooth, value: hovered)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private var fill: Double {
        if selected { return hovered ? Design.Fill.selectedHover : Design.Fill.selected }
        return hovered ? Design.Fill.hover : 0
    }
}
