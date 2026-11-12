import SunsetMetrics
import SunsetPane
import SwiftUI

/// One tab in the sidebar (its padding, radius and close button from `layout.*`), the title cut with "…" when it does not fit. While the pointer is over it a close button
/// appears and the row is highlighted; the selected tab has a stronger highlight, dimmer when the window is not the active one, and the hairline stroke
/// that the terminal card has (only the selected tab has it).
struct SidebarRow: View {
    let model: (any PaneContent)?
    let selected: Bool
    var armed = false
    /// Kept true when the row just slid into the slot of a tab whose close button was clicked, so rapid clicks on the same spot close tabs without needing
    /// pointer movement (`n27`).
    var keepCloseVisible = false
    var name: String?
    var icon: PaneIcon?
    /// What the row's pane would start from, when it is not running (a kept entry that is not open), and the command it would run.
    var saved: PaneDescriptor?
    var savedCommand: String?
    let showIcon: Bool
    let showTitle: Bool
    let showDirectory: Bool
    let showProgress: Bool
    let layout: ShellSettings.Layout
    /// What the button at the row's end does: close a tab, unload a kept entry, delete one that is not open.
    var button = Button.close
    /// Open (every tab, an open kept entry): a faint fill at rest. A kept entry that is not open has none, and is not dimmed (owner,
    /// 2026-11-12: dimmed looked disabled).
    var open = true
    /// A row of the Favorites tree: one line is `Design.Size.favoriteRow` tall instead of `tabRow`.
    var compact = false
    /// One of several rows selected together (R3 step d): drawn lighter than the shown row.
    var marked = false
    /// While its name is edited in place: the field's first text, and what to do with the result (nil: Escape, nothing changes).
    var renaming: (start: String, done: (String?) -> Void)?
    let close: () -> Void

    enum Button {
        case close, unload, delete

        var symbol: String { self == .unload ? "minus" : "xmark" }
        var help: String {
            switch self {
                case .close: "Close Tab"
                case .unload: "Unload (it stays in Favorites)"
                case .delete: "Remove from Favorites"
            }
        }
    }
    @State private var hovering = false
    @State private var overClose = false
    @Environment(\.controlActiveState) private var activeState

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: layout.tabRadius, style: .continuous)
        return HStack(spacing: 4) {
            if let renaming {
                RenameField(start: renaming.start, done: renaming.done)
                    .frame(maxWidth: .infinity, minHeight: layout.closeButtonSize, alignment: .leading)
            } else {
                TabLabel(
                    model: model,
                    showIcon: showIcon,
                    showTitle: showTitle,
                    showDirectory: showDirectory,
                    showProgress: showProgress,
                    name: name,
                    icon: icon,
                    saved: saved,
                    savedCommand: savedCommand
                )
                .frame(maxWidth: .infinity, minHeight: layout.closeButtonSize, alignment: .leading)
            }
        }
        .mask { titleMask }
        .padding(.leading, layout.tabPaddingLeading)
        .padding(
            .vertical,
            Design.rowPadding(layout, lines: lines, height: compact ? Design.Size.favoriteRow : Design.Size.tabRow)
        )
        .padding(.trailing, layout.tabPaddingTrailing)
        // As far from the trailing edge as from the top and the bottom (owner, 2026-11-12): centred on a point half the row's height in.
        .overlay {
            GeometryReader { proxy in
                closeButton.position(x: proxy.size.width - proxy.size.height / 2, y: proxy.size.height / 2)
            }
        }
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
        if marked, !selected { return Color(nsColor: .controlAccentColor).opacity(hovering ? 0.26 : 0.18) }
        return switch (selected, hovering || keepCloseVisible) {
            case (true, true): .primary.opacity(activeState == .inactive ? 0.12 : 0.2)
            case (true, false): .primary.opacity(activeState == .inactive ? 0.08 : 0.14)
            case (false, true): .primary.opacity(open ? Design.Fill.openHover : Design.Fill.hover)
            case (false, false): open ? .primary.opacity(Design.Fill.open) : .clear
        }
    }

    /// Two lines when the directory (or a page's address) is shown and there is one.
    private var lines: Int { showDirectory && (model?.detail ?? saved?.directory) != nil ? 2 : 1 }

    /// Over the row's end, so that the title has the whole width while it is hidden (owner note n65); shown, the title fades out under it.
    private var closeButton: some View {
        SwiftUI.Button(action: close) {
            Image(systemName: button.symbol)
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
        .help(armed ? "Click again to close running command" : button.help)
    }

    private var showsClose: Bool { hovering || armed || keepCloseVisible }

    /// The title runs to the row's end; under a shown close button it fades out over a few points.
    private var titleMask: some View {
        HStack(spacing: 0) {
            Color.black
            if showsClose && renaming == nil {
                LinearGradient(colors: [.black, .clear], startPoint: .leading, endPoint: .trailing).frame(width: 8)
                // The close button sits half the row's height from its edge, a little further in on a taller row.
                Color.clear.frame(width: layout.closeButtonSize + Design.Space.xs)
            }
        }
    }
}
