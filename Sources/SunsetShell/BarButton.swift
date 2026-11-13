import SwiftUI

/// The icon buttons of a bar (the address bar's back, forward, reload; the find bar's arrows): `SidebarIconButton` at the field's height and
/// corner, so that buttons and field line up and nest in the bar's corner at its inset.
package enum BarButton {
    package static func metrics(_ surface: SurfaceStyle, radius: Double? = nil) -> SidebarButtonMetrics {
        SidebarButtonMetrics(
            size: CGSize(width: Design.Size.field, height: Design.Size.field),
            radius: radius ?? surface.leafRadius,
            smooth: surface.layout.smooth
        )
    }
}
