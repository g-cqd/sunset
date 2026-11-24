import SwiftUI

/// The surface fill shared by floating cards (`SurfaceModifier`) and popovers (`PopoverSurfaceModifier`): the window's
/// surface (`surfaceStyle`), optionally tinted with `Design.Fill.popoverShade` so popovers and previews share one
/// middle-ground look.
struct SurfaceFill<S: InsettableShape>: View {
    let shape: S
    let style: SurfaceStyle
    let shade: Color?

    var body: some View {
        ZStack {
            switch style.kind {
                case .glass: Color.clear.glassEffect(style.clearGlass ? .clear : .regular, in: shape)
                case .material: shape.fill(.regularMaterial)
                case .opaque: shape.fill(Design.Raised.color)
                case .fill: shape.fill(style.fillColor)
            }
            if let shade { shape.fill(shade) }
        }
    }
}
