import SwiftUI

/// The container under a sidebar button's symbol, which knows whether the pointer is over it.
struct SidebarIconButtonFace<Label: View>: View {
    let label: Label
    let pressed: Bool
    let metrics: SidebarButtonMetrics
    @State private var hovering = false
    @Environment(\.isEnabled) private var enabled
    /// The corner of this button that is at the window's corner, when it is the one there.
    @Environment(\.sidebarButtonCorner) private var corner

    var body: some View {
        let shape = SidebarButtonCorner.shape(metrics, at: corner)
        label
            .foregroundStyle(
                !enabled ? AnyShapeStyle(.tertiary) : AnyShapeStyle(hovering || pressed ? .primary : .secondary)
            )
            .frame(width: metrics.size.width, height: metrics.size.height)
            .background(
                shape.fill(
                    .primary.opacity(
                        !enabled ? 0 : pressed ? Design.Fill.pressed : (hovering ? Design.Fill.openHover : 0)
                    )
                )
            )
            .contentShape(shape)
            // The press is felt (the owner's note n11): the glyph gives a little under the pointer.
            .scaleEffect(pressed && enabled ? Design.Motion.pressedScale : 1)
            .onHover { hovering = $0 }
            .animation(metrics.smooth, value: hovering)
            .animation(.snappy(duration: 0.12), value: pressed)
    }
}
