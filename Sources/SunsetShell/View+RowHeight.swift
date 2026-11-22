package import SunsetMetrics
package import SwiftUI

extension View {
    /// A row's height: one line, exactly `Design.oneLineHeight` whatever is in it; more lines, their own height with
    /// the row's padding.
    @ViewBuilder package func rowHeight(_ layout: LayoutMetrics, lines: Int, height: Double) -> some View {
        if lines > 1 {
            padding(.vertical, Design.rowPadding(layout, lines: lines, height: height))
        } else {
            frame(height: Design.oneLineHeight(layout, height: height))
        }
    }
}
