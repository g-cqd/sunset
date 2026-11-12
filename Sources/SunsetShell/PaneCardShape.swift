package import SwiftUI

/// The focused pane's card, in the pane area's coordinates: its frame and its corners. What lies over the pane area for that pane
/// (the window's address bar's blur) is cut to it, so it does not reach the gaps or the sidebar (owner, 2026-11-13).
package struct PaneCardShape: Shape, Equatable {
    package var frame: CGRect
    package var radii: RectangleCornerRadii

    package init(frame: CGRect, radii: RectangleCornerRadii) {
        self.frame = frame
        self.radii = radii
    }

    package func path(in rect: CGRect) -> Path {
        UnevenRoundedRectangle(cornerRadii: radii, style: .continuous).path(in: frame)
    }

    /// Published by the pane area for its focused pane.
    package struct Key: PreferenceKey {
        package static let defaultValue: PaneCardShape? = nil
        package static func reduce(value: inout PaneCardShape?, nextValue: () -> PaneCardShape?) {
            value = nextValue() ?? value
        }
    }
}
