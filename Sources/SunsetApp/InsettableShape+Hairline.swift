import SwiftUI

extension InsettableShape {
    /// The thin line drawn on the terminal card and on the sidebar's tabs and panel: half a point wide, a tenth of the label colour, inside the shape.
    func hairline() -> some View {
        strokeBorder(.primary.opacity(0.12), lineWidth: 0.5).allowsHitTesting(false)
    }
}
