import SwiftUI

/// One tab in the sidebar: 6 pt rounded, padded 8 pt on the leading edge and 3 to 4 pt on the others, the title cut with "…" when it does not fit. While the pointer is over it a 20 × 20 pt close button
/// appears and the row is highlighted; the selected tab has a stronger highlight, dimmer when the window is not the active one, and the hairline stroke
/// that the terminal card has (only the selected tab has it).
struct SidebarRow: View {
    let model: TerminalModel?
    let selected: Bool
    let showTitle: Bool
    let showDirectory: Bool
    let showProgress: Bool
    let close: () -> Void
    @State private var hovering = false
    @State private var overClose = false
    @Environment(\.controlActiveState) private var activeState

    private static let radius = 6.0
    /// The one transition between states: short, eased, nothing more.
    static let smooth = Animation.easeInOut(duration: 0.15)
    /// The close button's side. The label is at least this tall whether the button shows or not, so that a row does not change height under the pointer.
    private static let buttonSize = 20.0

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: Self.radius, style: .continuous)
        return HStack(spacing: 4) {
            TabLabel(model: model, showTitle: showTitle, showDirectory: showDirectory, showProgress: showProgress)
                .frame(maxWidth: .infinity, minHeight: Self.buttonSize, alignment: .leading)
            // Always laid out and only faded, so that the row never changes size and the label does not jump.
            Button(action: close) {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .semibold))
                    .frame(width: Self.buttonSize, height: Self.buttonSize)
                    .background(
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(.primary.opacity(overClose ? 0.14 : 0))
                    )
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .opacity(hovering ? 1 : 0)
            .allowsHitTesting(hovering)
            .onHover { overClose = $0 }
            .help("Close Tab")
        }
        .padding(.leading, 8)
        .padding(.vertical, 3)
        .padding(.trailing, 4)
        .background(shape.fill(highlight))
        .overlay { shape.hairline().opacity(selected ? 1 : 0) }
        .contentShape(shape)
        .onHover { hovering = $0 }
        .animation(Self.smooth, value: hovering)
        .animation(Self.smooth, value: overClose)
        .animation(Self.smooth, value: selected)
        .animation(Self.smooth, value: activeState)
    }

    /// Hover and selection variants of the highlight.
    private var highlight: Color {
        switch (selected, hovering) {
            case (true, true): .primary.opacity(activeState == .inactive ? 0.12 : 0.2)
            case (true, false): .primary.opacity(activeState == .inactive ? 0.08 : 0.14)
            case (false, true): .primary.opacity(0.07)
            case (false, false): .clear
        }
    }
}
