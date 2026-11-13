import SwiftUI

/// The circle under a `TabCapsuleButton`'s symbol, which knows whether the pointer is over it.
struct TabCapsuleButtonFace<Label: View>: View {
    let label: Label
    let pressed: Bool
    @State private var hovering = false
    @Environment(\.isEnabled) private var enabled
    @Environment(\.surfaceStyle) private var surface

    var body: some View {
        let side = Design.TabCapsules.height
        label
            .foregroundStyle(
                !enabled ? AnyShapeStyle(.tertiary) : AnyShapeStyle(hovering || pressed ? .primary : .secondary)
            )
            .frame(width: side, height: side)
            .background(Circle().fill(.primary.opacity(fill)))
            .overlay { Circle().hairline(surface.layout) }
            .contentShape(Circle())
            .onHover { hovering = $0 }
            .animation(surface.layout.smooth, value: hovering)
    }

    private var fill: Double {
        guard enabled else { return Design.Fill.field }
        return pressed ? Design.Fill.pressed : hovering ? Design.Fill.openHover : Design.Fill.field
    }
}
