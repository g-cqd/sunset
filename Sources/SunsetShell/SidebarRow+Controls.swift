import SunsetHelp
import SunsetMetrics
import SwiftUI

/// The controls at a row's end besides its close button: the cup of a row kept awake, the clear button of a row renamed.
extension SidebarRow {
    /// Empties the name being typed; left empty, the row takes back its own title.
    var clearButton: some View {
        SwiftUI.Button {
            typed = ""
        } label: {
            Image(systemName: "delete.left")
                .font(.system(size: Design.Symbol.badge, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(width: layout.closeButtonSize, height: layout.closeButtonSize)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .focusable(false)
        .help("Clear the Name")
        .accessibilityLabel("Clear the Name")
    }

    /// Kept awake (roadmap 0038 C): the close button's size, its symbol's size and weight, in its place while it is hidden.
    /// While the row is pointed at it is a button beside the close button (note n5), slashed under the pointer: a click lets
    /// the Mac sleep again.
    @ViewBuilder var awakeMark: some View {
        if showsClose, let stopAwake {
            SwiftUI.Button(action: stopAwake) { cup(slashed: overAwake) }
                .buttonStyle(.plain)
                .keptHover($overAwake)
                .help("Stop Keeping the Mac Awake")
                .accessibilityLabel("Stop Keeping the Mac Awake")
        } else {
            cup(slashed: false)
                .helpTopic(.keepAwake)
                .accessibilityElement()
                .accessibilityLabel("Keeps the Mac awake")
        }
    }

    private func cup(slashed: Bool) -> some View {
        Image(systemName: "cup.and.saucer.fill")
            .font(.system(size: Design.Symbol.badge, weight: .semibold))
            .foregroundStyle(slashed ? Color.primary : Color.secondary)
            // No slashed cup among the symbols: a slash drawn over it, as the symbols' own.
            .overlay {
                if slashed {
                    Capsule()
                        .fill(Color.primary)
                        .frame(width: Design.Space.hair, height: layout.closeButtonSize * Self.slashShare)
                        .rotationEffect(.degrees(Self.slashAngle))
                }
            }
            .frame(width: layout.closeButtonSize, height: layout.closeButtonSize)
            .background(
                RoundedRectangle(cornerRadius: layout.closeButtonRadius, style: .continuous)
                    .fill(Color.primary.opacity(slashed ? Design.Fill.selected : 0))
            )
            .contentShape(.rect)
    }

    /// The slash over the cup: its share of the button's height, and its angle.
    private static let slashShare = 0.7
    private static let slashAngle = -45.0
}
