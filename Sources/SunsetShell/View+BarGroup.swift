package import SwiftUI

extension View {
    /// A group of a bar's controls, the way the system's toolbar draws them (owner, 2026-11-13): regular glass in a shape concentric
    /// with the container it sits in (`containerShape`, the pane's card), and under it its own variable blur, reaching `margin` up to
    /// the container's edge, falling away below and at both ends, so that it has no side of its own.
    package func barGroup(margin: Double, top: Bool = true) -> some View {
        modifier(BarGroup(margin: margin, top: top))
    }
}
