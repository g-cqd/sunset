package import AemiSDR

/// How a floating panel's blur reaches past it (`View.blurSurface(_:shadow:halo:)`): from the corner of the pane it is set in (full
/// over the `margin` between the panel and that corner), falling to none from `inset` inside the panel's other two sides to `reach`
/// outside them (owner, 2026-11-13).
package struct BlurHalo: Equatable, Sendable {
    package var corner: BlurMask.Corner
    package var margin: Double
    package var inset: Double
    package var reach: Double

    package init(corner: BlurMask.Corner, margin: Double, inset: Double, reach: Double) {
        self.corner = corner
        self.margin = margin
        self.inset = inset
        self.reach = reach
    }
}
