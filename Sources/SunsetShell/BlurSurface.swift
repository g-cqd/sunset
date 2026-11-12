import AemiSDR
import SwiftUI

/// The look of `View.blurSurface(_:shadow:halo:)`.
struct BlurSurface: ViewModifier {
    let shape: RoundedRectangle
    let shadow: Design.Shadow?
    let halo: BlurHalo?
    @Environment(\.barBlur) private var choice
    @Environment(\.surfaceStyle) private var surface

    func body(content: Content) -> some View {
        if choice == .variable {
            content
                .background {
                    ZStack {
                        blur
                        shape.fill(Color.black.opacity(Design.Fill.barShade))
                            .shadow(
                                color: .black.opacity(shadow?.opacity ?? 0),
                                radius: shadow?.radius ?? 0,
                                y: shadow?.y ?? 0
                            )
                    }
                }
                .overlay { shape.hairline(surface.layout) }
        } else {
            content.surface(shape, shadow: shadow)
        }
    }

    @ViewBuilder private var blur: some View {
        if let halo {
            GeometryReader { proxy in
                BlurBackdropView(
                    Design.Blur.halo(halo, width: proxy.size.width, height: proxy.size.height)
                )
            }
            .padding(Self.outsets(halo))
        } else {
            BlurBackdropView(Design.Blur.panel).clipShape(shape)
        }
    }

    /// Out to the corner on its two sides, `reach` past the panel on the others.
    private static func outsets(_ halo: BlurHalo) -> EdgeInsets {
        let top = halo.corner == .topLeading || halo.corner == .topTrailing
        let leading = halo.corner == .topLeading || halo.corner == .bottomLeading
        return EdgeInsets(
            top: -(top ? halo.margin : halo.reach),
            leading: -(leading ? halo.margin : halo.reach),
            bottom: -(top ? halo.reach : halo.margin),
            trailing: -(leading ? halo.reach : halo.margin)
        )
    }
}
