package import SwiftUI

extension View {
    /// A floating panel's surface (the find bar): with `appearance.barBlur` variable, a tuned blur of what is under it in its shape
    /// (Sunset research/blur, variant A), with the hairline and the shadow; otherwise the window's surface (`surface(_:shadow:)`).
    package func blurSurface(_ shape: RoundedRectangle, shadow: Design.Shadow? = nil) -> some View {
        modifier(BlurSurface(shape: shape, shadow: shadow))
    }
}
