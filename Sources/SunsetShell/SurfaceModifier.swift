import SwiftUI

/// The background of a surface: glass, a material, a raised colour (slightly lighter than the window), or the tint's colour fill.
struct SurfaceModifier<S: InsettableShape>: ViewModifier {
    let shape: S
    let shadow: Design.Shadow?
    let shaded: Bool
    @Environment(\.surfaceStyle) private var style
    @Environment(\.barTint) private var tint
    @Environment(\.colorScheme) private var outer

    func body(content: Content) -> some View {
        let resolved = shaded ? tint.shaded(in: outer) : nil
        content
            .background {
                if style.kind != .glass {
                    SurfaceFill(shape: shape, style: style, shade: resolved?.shade)
                } else if let shade = resolved?.shade {
                    shape.fill(shade)
                }
            }
            .modifier(GlassSurface(enabled: style.kind == .glass, clear: style.clearGlass, shape: shape))
            .environment(\.colorScheme, resolved?.scheme ?? outer)
            .overlay { shape.hairline(style.layout) }
            .shadow(
                color: .black.opacity(shadow?.opacity ?? 0),
                radius: shadow?.radius ?? 0,
                y: shadow?.y ?? 0
            )
    }
}
