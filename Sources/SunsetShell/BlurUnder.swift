import AemiSDR
import SwiftUI

/// The look of `View.blurUnder(_:solid:fade:radius:)`.
struct BlurUnder: ViewModifier {
    let edge: BlurMask.Edge
    let solid: Double
    let fade: Double
    let radius: Double
    @Environment(\.barBlur) private var choice

    func body(content: Content) -> some View {
        content.background(alignment: edge == .top ? .top : .bottom) {
            if choice == .variable {
                BlurBackdropView(
                    Design.Blur.under(edge, solid: solid, fade: fade, radius: radius)
                )
                .frame(height: solid + fade)
                .allowsHitTesting(false)
            }
        }
    }
}
