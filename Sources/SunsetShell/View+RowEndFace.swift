import SunsetMetrics
import SwiftUI

extension View {
    /// A control at a row's end: the close button's size, its rounded fill when `lit`, the whole square clickable.
    func rowEndFace(_ layout: ShellSettings.Layout, lit: Bool) -> some View {
        frame(width: layout.closeButtonSize, height: layout.closeButtonSize)
            .background(
                RoundedRectangle(cornerRadius: layout.closeButtonRadius, style: .continuous)
                    .fill(Color.primary.opacity(lit ? Design.Fill.selected : 0))
            )
            .contentShape(.rect)
    }
}
