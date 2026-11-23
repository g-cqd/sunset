import SunsetMetrics
import SunsetPane
import SwiftUI

/// One small tab inside a split tab's container: its title, a slight highlight under the pointer, and, when it is the focused pane of the selected tab, a
/// stronger one with the same hairline the selected tab row has.
struct SidebarGroupPart: View {
    let model: (any PaneContent)?
    /// What a pane of a kept entry that is not open would start from (its title and picture).
    var saved: PaneDescriptor?
    let lit: Bool
    let layout: ShellSettings.Layout
    /// Its height: the row's, less the container's inset above and below.
    var height: Double = Design.Size.tabRow - 2 * Design.Space.hair
    var onHoverChange: (Bool) -> Void = { _ in }
    let select: () -> Void
    @State private var hovering = false
    @State private var width = Design.Size.iconOnlyBelow
    @Environment(\.controlActiveState) private var activeState
    @Environment(\.siteTint) private var siteTint

    var body: some View {
        let shape = RoundedRectangle(
            cornerRadius: ConcentricRadius.inner(outer: layout.tabRadius, inset: Design.Space.hair),
            style: .continuous
        )
        // Its picture and title from its leading edge; only the picture, centred, when there is no room for a title.
        let iconOnly = width < Design.Size.iconOnlyBelow
        TabLabel(
            model: model,
            parts: TabParts(icon: true, title: !iconOnly, directory: false, progress: false),
            saved: saved
        )
        .padding(.horizontal, iconOnly ? 0 : Design.Space.xs)
        .frame(maxWidth: .infinity, minHeight: height, alignment: iconOnly ? .center : .leading)
        .onGeometryChange(for: Double.self, of: { $0.size.width }, action: { width = $0 })
        .background(shape.fill(highlight))
        .overlay { shape.hairline(layout).opacity(lit ? 1 : 0) }
        .contentShape(shape)
        .onHover { inside in
            hovering = inside
            onHoverChange(inside)
        }
        .animation(layout.smooth, value: hovering)
        .animation(layout.smooth, value: lit)
        .animation(layout.smooth, value: activeState)
        .onTapGesture(perform: select)
    }

    private var highlight: Color {
        let color = RowFill.tabColor(custom: nil, model: model)
        if let tint = RowFill.siteTint(siteTint, selected: lit, hovering: hovering, color: color) {
            return tint.color
        }
        let fill = RowFill.opacity(selected: lit, hovering: hovering, inactive: activeState == .inactive, open: false)
        return fill == 0 ? .clear : .primary.opacity(fill)
    }
}
