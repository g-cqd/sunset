package import SwiftUI

extension View {
    /// Draws this view on a floating surface in `shape`, the way the window's `surfaceStyle` says, with the hairline and a shadow (design 0003 §6).
    package func surface<S: InsettableShape>(_ shape: S, shadow: Design.Shadow? = nil) -> some View {
        modifier(SurfaceModifier(shape: shape, shadow: shadow))
    }
}
