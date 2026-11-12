import AemiSDR
import SwiftUI

/// The look of `View.blurSurface(_:shadow:)`.
struct BlurSurface: ViewModifier {
    let shape: RoundedRectangle
    let shadow: Design.Shadow?
    @Environment(\.barBlur) private var choice
    @Environment(\.surfaceStyle) private var surface

    func body(content: Content) -> some View {
        if choice == .variable {
            content
                .background { BlurBackdropView(Design.Blur.panel).clipShape(shape) }
                .overlay { shape.hairline(surface.layout) }
                .shadow(color: .black.opacity(shadow?.opacity ?? 0), radius: shadow?.radius ?? 0, y: shadow?.y ?? 0)
        } else {
            content.surface(shape, shadow: shadow)
        }
    }
}
