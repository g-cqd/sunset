import SwiftUI

/// The look of `View.tabCapsule()`.
struct TabCapsuleLook: ViewModifier {
    @Environment(\.surfaceStyle) private var surface

    func body(content: Content) -> some View {
        content
            .frame(height: Design.TabCapsules.height)
            .background(Capsule().fill(.primary.opacity(Design.Fill.field)))
            .overlay { Capsule().hairline(surface.layout) }
            .environment(\.controlRadius, Design.TabCapsules.radius)
            .environment(\.controlHeight, Design.TabCapsules.height)
            .environment(\.controlPadding, Design.BarGroup.fieldPadding)
    }
}
