package import SwiftUI

/// Which corner of a sidebar button is at the window's corner: that one shares its centre with the window's (the owner,
/// 2026-11-15, his choice A1), the three others keep the radius every sidebar button has.
package enum SidebarButtonCorner: Sendable {
    case bottomLeading
    case bottomTrailing

    /// The button's shape: `radius` everywhere, `windowCorner` at this corner.
    package func shape(_ metrics: SidebarButtonMetrics) -> UnevenRoundedRectangle {
        Self.shape(metrics, at: self)
    }

    /// The shape of a button with `corner` at the window's corner, or none.
    package static func shape(_ metrics: SidebarButtonMetrics, at corner: Self?) -> UnevenRoundedRectangle {
        UnevenRoundedRectangle(
            topLeadingRadius: metrics.radius,
            bottomLeadingRadius: corner == .bottomLeading ? metrics.windowCorner : metrics.radius,
            bottomTrailingRadius: corner == .bottomTrailing ? metrics.windowCorner : metrics.radius,
            topTrailingRadius: metrics.radius,
            style: .continuous
        )
    }
}

extension EnvironmentValues {
    /// Set on the one button that is at the window's bottom corner.
    @Entry package var sidebarButtonCorner: SidebarButtonCorner?
}
