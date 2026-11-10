import SunsetConfig
import SwiftUI

/// One tab in the sidebar (its padding, radius and close button from `layout.*`), the title cut with "…" when it does not fit. While the pointer is over it a close button
/// appears and the row is highlighted; the selected tab has a stronger highlight, dimmer when the window is not the active one, and the hairline stroke
/// that the terminal card has (only the selected tab has it).
struct SidebarRow: View {
    let model: TerminalModel?
    let selected: Bool
    var armed = false
    /// Kept true when the row just slid into the slot of a tab whose close button was clicked, so rapid clicks on the same spot close tabs without needing
    /// pointer movement (`n27`).
    var keepCloseVisible = false
    let showIcon: Bool
    let showTitle: Bool
    let showDirectory: Bool
    let showProgress: Bool
    let layout: Configuration.Layout
    let close: () -> Void
    @State private var hovering = false
    @State private var overClose = false
    @Environment(\.controlActiveState) private var activeState

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: layout.tabRadius, style: .continuous)
        return HStack(spacing: 4) {
            TabLabel(
                model: model,
                showIcon: showIcon,
                showTitle: showTitle,
                showDirectory: showDirectory,
                showProgress: showProgress
            )
            .frame(maxWidth: .infinity, minHeight: layout.closeButtonSize, alignment: .leading)
            // Always laid out and only faded, so that the row never changes size and the label does not jump.
            Button(action: close) {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(armed ? Color.white : Color.primary)
                    .frame(width: layout.closeButtonSize, height: layout.closeButtonSize)
                    .background(
                        RoundedRectangle(cornerRadius: layout.closeButtonRadius, style: .continuous)
                            .fill(
                                armed
                                    ? Color.red.opacity(overClose ? 0.85 : 0.7)
                                    : Color.primary.opacity(overClose ? 0.14 : 0)
                            )
                    )
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .opacity(hovering || armed || keepCloseVisible ? 1 : 0)
            .allowsHitTesting(hovering || armed || keepCloseVisible)
            .onHover { overClose = $0 }
            .help(armed ? "Click again to close running command" : "Close Tab")
        }
        .padding(.leading, layout.tabPaddingLeading)
        .padding(.vertical, layout.tabPaddingVertical)
        .padding(.trailing, layout.tabPaddingTrailing)
        .background(shape.fill(highlight))
        .overlay {
            if armed {
                shape.strokeBorder(Color.red.opacity(0.65), lineWidth: 1).allowsHitTesting(false)
            } else {
                shape.hairline(layout).opacity(selected ? 1 : 0)
            }
        }
        .contentShape(shape)
        .onHover { hovering = $0 }
        .animation(layout.smooth, value: hovering)
        .animation(layout.smooth, value: overClose)
        .animation(layout.smooth, value: selected)
        .animation(layout.smooth, value: armed)
        .animation(layout.smooth, value: activeState)
    }

    /// Hover and selection variants of the highlight.
    private var highlight: Color {
        if armed { return .red.opacity(hovering || keepCloseVisible ? 0.28 : 0.2) }
        return switch (selected, hovering || keepCloseVisible) {
            case (true, true): .primary.opacity(activeState == .inactive ? 0.12 : 0.2)
            case (true, false): .primary.opacity(activeState == .inactive ? 0.08 : 0.14)
            case (false, true): .primary.opacity(0.07)
            case (false, false): .clear
        }
    }
}
