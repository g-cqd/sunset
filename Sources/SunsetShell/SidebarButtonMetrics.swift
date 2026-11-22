package import SwiftUI

/// The container of a sidebar button (`SidebarIconButton`): set by the sidebar, read by every button in it, so the pin, the + and the downloads button
/// are one size and one corner.
package struct SidebarButtonMetrics: Sendable {
    package var size = CGSize(width: 28, height: 28)
    package var radius = 7.0
    package var smooth: Animation? = .default
    /// The radius of the corner that is at the window's corner, for the button that is there (`SidebarButtonCorner`).
    package var windowCorner = 7.0

    package init(
        size: CGSize = CGSize(width: 28, height: 28),
        radius: Double = 7,
        smooth: Animation? = .default,
        windowCorner: Double? = nil
    ) {
        self.size = size
        self.radius = radius
        self.smooth = smooth
        self.windowCorner = windowCorner ?? radius
    }
}

extension SidebarButtonMetrics {
    /// The same button, `width` wide (a Space's dot).
    package func narrowed(to width: Double) -> Self {
        var narrow = self
        narrow.size.width = width
        return narrow
    }
}

extension EnvironmentValues {
    @Entry package var sidebarButtonMetrics = SidebarButtonMetrics()
}
