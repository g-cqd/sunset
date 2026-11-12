import SwiftUI

/// The background of a surface: glass, a material, a raised colour (slightly lighter than the window), or the tint's colour fill.
struct SurfaceModifier<S: InsettableShape>: ViewModifier {
    let shape: S
    let shadow: Design.Shadow?
    @Environment(\.surfaceStyle) private var style

    func body(content: Content) -> some View {
        styled(content)
            .overlay { shape.hairline(style.layout) }
            .shadow(
                color: .black.opacity(shadow?.opacity ?? 0),
                radius: shadow?.radius ?? 0,
                y: shadow?.y ?? 0
            )
    }

    @ViewBuilder private func styled(_ content: Content) -> some View {
        switch style.kind {
            case .glass: content.glassEffect(style.clearGlass ? .clear : .regular, in: shape)
            // Drawn as a shape behind, not `.background(_:in:)`: that turns the content vibrant, and over a light page the secondary text and
            // the borderless buttons all but vanished (seen 2026-11-12).
            case .material: content.background { shape.fill(.regularMaterial) }
            case .opaque: content.background(shape.fill(Design.Raised.color))
            case .fill: content.background(shape.fill(style.fillColor))
        }
    }
}
