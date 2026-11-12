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

    /// Published by the pane area: where it is, and its focused pane's card (nil when nothing is shown). What the window lays over
    /// the panes (the address bar, the command bar) is placed by it.
    package struct Area {
        package var bounds: Anchor<CGRect>
        package var card: PaneCardShape?

        package init(bounds: Anchor<CGRect>, card: PaneCardShape?) {
            self.bounds = bounds
            self.card = card
        }
    }

    package struct Key: PreferenceKey {
        package static let defaultValue: Area? = nil
        package static func reduce(value: inout Area?, nextValue: () -> Area?) {
            value = nextValue() ?? value
        }
    }
}
