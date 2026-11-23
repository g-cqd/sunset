import SunsetMetrics
import SwiftUI

/// `QuietButtonStyle`'s face, and `RowGlyphButton`'s.
struct QuietButtonFace<Label: View>: View {
    let label: Label
    let pressed: Bool
    let layout: ShellSettings.Layout
    let inset: Double
    @State private var hovering = false
    @Environment(\.isEnabled) private var enabled

    var body: some View {
        label
            .foregroundStyle(enabled && (hovering || pressed) ? .primary : .secondary)
            .padding(.horizontal, inset)
            .frame(minWidth: layout.closeButtonSize, minHeight: layout.closeButtonSize)
            .background(
                RoundedRectangle(cornerRadius: layout.closeButtonRadius, style: .continuous)
                    .fill(
                        .primary.opacity(
                            !enabled ? 0 : pressed ? Design.Fill.pressed : hovering ? Design.Fill.selected : 0
                        )
                    )
            )
            .contentShape(.rect)
            // The press is felt.
            .scaleEffect(pressed ? Design.Motion.pressedScale : 1)
            .keptHover($hovering)
            .animation(layout.smooth, value: hovering)
            .animation(.snappy(duration: 0.12), value: pressed)
    }
}
