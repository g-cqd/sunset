package import AemiSDR
package import SwiftUI

extension View {
    /// A fading blur under this bar (when `appearance.barBlur` is variable): full over `solid` points from `edge`, falling to none
    /// over `fade` points beyond the bar. It takes no clicks, and draws outside the bar's frame on purpose.
    package func blurUnder(_ edge: BlurMask.Edge, solid: Double, fade: Double, radius: Double = Design.Blur.barRadius)
        -> some View
    {
        modifier(BlurUnder(edge: edge, solid: solid, fade: fade, radius: radius))
    }
}
