import SunsetConfig
import SwiftUI

extension InsettableShape {
    /// The thin line drawn on the terminal card and on the sidebar's selected tab and panel, inside the shape: its width and opacity are `layout.hairline*`.
    func hairline(_ layout: Configuration.Layout) -> some View {
        strokeBorder(.primary.opacity(layout.hairlineOpacity), lineWidth: layout.hairlineWidth).allowsHitTesting(false)
    }
}
