import SwiftUI

/// One tab in the sidebar: padded 8 pt, rounded 8 pt, the title cut with "…" when it does not fit. While the pointer is over it a 24 × 24 pt close button
/// appears and the row is highlighted; the selected tab has a stronger highlight, dimmer when the window is not the active one.
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

    private static let radius = 8.0

    var body: some View {
        HStack(spacing: 4) {
            TabLabel(model: model, showTitle: showTitle, showDirectory: showDirectory, showProgress: showProgress)
                .frame(maxWidth: .infinity, alignment: .leading)
            if hovering {
                Button(action: close) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .semibold))
                        .frame(width: 24, height: 24)
                        .background(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(.primary.opacity(overClose ? 0.14 : 0))
                        )
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .onHover { overClose = $0 }
                .help("Close Tab")
            }
        }
        .padding(8)
        .background(RoundedRectangle(cornerRadius: Self.radius, style: .continuous).fill(highlight))
        .contentShape(RoundedRectangle(cornerRadius: Self.radius, style: .continuous))
        .onHover { hovering = $0 }
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
