import SunsetMetrics
package import SwiftUI

extension InsettableShape {
    /// The thin line drawn on the terminal card and on the sidebar's selected tab and panel, inside the shape: its width and opacity are `layout.hairline*`.
    package func hairline(_ layout: ShellSettings.Layout) -> some View {
        strokeBorder(.primary.opacity(layout.hairlineOpacity), lineWidth: layout.hairlineWidth).allowsHitTesting(false)
    }

    /// A slightly stronger hairline when the pointer is over this pane's sub-tab in the split container, showing which pane a click would focus.
    package func hoverHairline(_ layout: ShellSettings.Layout) -> some View {
        strokeBorder(
            .primary.opacity(min(layout.hairlineOpacity * 2.5, 0.45)),
            lineWidth: max(layout.hairlineWidth * 1.5, 1)
        )
        .allowsHitTesting(false)
    }

    /// The same line in the system accent colour, a little stronger: the focused terminal's card in a split.
    package func focusHairline(_ layout: ShellSettings.Layout, accent: Color) -> some View {
        strokeBorder(accent.opacity(Design.Fill.focusLine), lineWidth: max(layout.hairlineWidth * 2, 1))
            .allowsHitTesting(false)
    }
}
