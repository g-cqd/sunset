package import SwiftUI

extension View {
    /// A floating panel's surface (the find bar): with `appearance.barBlur` variable, a tuned blur of what is under it with the
    /// hairline, a dark shade and the shadow, cut to its shape or, with a `halo`, reaching its pane's corner and fading out into
    /// the page (Sunset research/blur); otherwise the window's surface (`surface(_:shadow:)`).
    package func blurSurface(_ shape: RoundedRectangle, shadow: Design.Shadow? = nil, halo: BlurHalo? = nil)
        -> some View
    {
        modifier(BlurSurface(shape: shape, shadow: shadow, halo: halo))
    }
}
