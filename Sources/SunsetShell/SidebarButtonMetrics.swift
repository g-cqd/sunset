package import SwiftUI

/// The container of a sidebar button (`SidebarIconButton`): set by the sidebar, read by every button in it, so the pin, the + and the downloads button
/// are one size and one corner.
package struct SidebarButtonMetrics: Sendable {
    package var size = CGSize(width: 28, height: 28)
    package var radius = 7.0
    package var smooth: Animation? = .default

    package init(size: CGSize = CGSize(width: 28, height: 28), radius: Double = 7, smooth: Animation? = .default) {
        self.size = size
        self.radius = radius
        self.smooth = smooth
    }
}

extension EnvironmentValues {
    @Entry package var sidebarButtonMetrics = SidebarButtonMetrics()
}
