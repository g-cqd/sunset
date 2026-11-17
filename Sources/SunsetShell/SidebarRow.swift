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
    /// What the button at the row's end does: close a tab, unload a kept entry, delete one that is not open, close an open document.
    var button = Button.close
    /// Open (every tab, an open kept entry): a faint fill at rest. A kept entry that is not open has none, and is not dimmed (owner,
    /// 2026-11-12: dimmed looked disabled).
    var open = true
    /// A row of the Favorites tree: one line is `Design.Size.favoriteRow` tall instead of `tabRow`.
    var compact = false
    /// One of several rows selected together (R3 step d): in the accent; stronger when it is also the shown row.
    var marked = false
    /// It keeps the Mac awake (roadmap 0035 E): a cup after its title.
    var awake = false
    /// Lets the Mac sleep again: the cup is a button while the row is pointed at (note n5).
    var stopAwake: (() -> Void)?
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
    @State var overAwake = false
    /// The name being typed while the row is renamed; nil: the name it started from.
    @State var typed: String?
    @Environment(\.controlActiveState) private var activeState
    @Environment(\.accent) private var accent

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: layout.tabRadius, style: .continuous)
        return HStack(spacing: Design.Space.xs) {
            if let renaming {
                // The row is the field: its picture stays, the text is where the title was (note n4).
                HStack(spacing: GlyphSpacing.toText) {
                    if showIcon {
                        TabIcon(
                            model: model,
                            icon: icon,
                            saved: saved,
                            savedCommand: savedCommand,
                            showsProgress: false
                        )
                    }
                    // Only the name being typed (the owner, 2026-11-17); the second line's room is kept, empty, so that the row
                    // keeps its height.
                    VStack(alignment: .leading, spacing: Design.Space.hair) {
                        RenameField(
                            text: Binding(get: { typed ?? renaming.start }, set: { typed = $0 }),
                            done: { name in
                                typed = nil
                                renaming.done(name)
                            }
                        )
                        // Clear of the clear button at the row's end.
                        .padding(.trailing, layout.closeButtonSize)
                        if lines > 1, let directory = model?.detail ?? saved?.directory {
                            Text(TabLabel.shortened(directory))
                                .font(Design.Text.detail)
                                .lineLimit(1)
                                .hidden()
                        }
                    }
                }
                .frame(maxWidth: .infinity, minHeight: layout.closeButtonSize, alignment: .leading)
            } else {
                TabLabel(
                    model: model,
                    showIcon: showIcon,
                    showTitle: showTitle,
                    showDirectory: showDirectory,
                    showProgress: showProgress,
                    showEdited: false,
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
        .rowHeight(layout, lines: lines, height: compact ? Design.Size.favoriteRow : Design.Size.tabRow)
        .padding(.trailing, layout.tabPaddingTrailing)
        // As far from the trailing edge as from the top and the bottom (owner, 2026-11-12): centred on a point half the row's height in.
        .overlay {
            GeometryReader { proxy in
                let middle = proxy.size.height / 2
                if renaming == nil {
                    closeButton.position(x: proxy.size.width - middle, y: middle)
                } else {
                    // Renaming: no close button; in its place, one that clears the name (the owner, 2026-11-17).
                    clearButton.position(x: proxy.size.width - middle, y: middle)
                }
                if edited { EditedMark().position(x: proxy.size.width - markInset(middle: middle), y: middle) }
                if awake { awakeMark.position(x: proxy.size.width - awakeInset(middle: middle), y: middle) }
            }
        }
        .background(shape.fill(highlight))
        .overlay {
            if armed {
                shape.strokeBorder(Color.red.opacity(Design.Fill.armedLine), lineWidth: 1).allowsHitTesting(false)
            } else if renaming != nil {
                // Being renamed: the row is the field, outlined as a field with the keyboard is.
                shape.focusHairline(layout, accent: accent.color)
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
        if armed { return .red.opacity(hovering || keepCloseVisible ? Design.Fill.armedHover : Design.Fill.armed) }
        switch RowEmphasis.of(shown: selected, marked: marked) {
            case .marked: return accent.color.opacity(hovering ? Design.Fill.markedHover : Design.Fill.marked)
            case .markedShown:
                return accent.color.opacity(hovering ? Design.Fill.markedShownHover : Design.Fill.markedShown)
            case .shown, .none: break
        }
        let inactive = activeState == .inactive
        return switch (selected, hovering || keepCloseVisible) {
            case (true, true):
                .primary.opacity(inactive ? Design.Fill.selectedInactiveHover : Design.Fill.selectedHover)
            case (true, false): .primary.opacity(inactive ? Design.Fill.selectedInactive : Design.Fill.selected)
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
                .font(.system(size: Design.Symbol.badge, weight: .semibold))
                .foregroundStyle(armed ? Color.white : Color.primary)
                .frame(width: layout.closeButtonSize, height: layout.closeButtonSize)
                .background(
                    RoundedRectangle(cornerRadius: layout.closeButtonRadius, style: .continuous)
                        .fill(
                            armed
                                ? Color.red.opacity(overClose ? Design.Fill.armedButtonHover : Design.Fill.armedButton)
                                : Color.primary.opacity(overClose ? Design.Fill.selected : 0)
                        )
                )
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .opacity(showsClose ? 1 : 0)
        .allowsHitTesting(showsClose)
        .onHover { overClose = $0 }
        .help(armed ? "Click again to close running command" : button.help)
    }

    var showsClose: Bool { hovering || armed || keepCloseVisible }

    /// How far the cup's centre is from the row's end: where the close button is, moved before it while it shows (the
    /// edited mark is before the cup).
    private func awakeInset(middle: Double) -> Double {
        showsClose ? middle + layout.closeButtonSize + Design.Space.xs : middle
    }

    /// The cup's room at the row's end, beside the close button's.
    private var awakeRoom: Double { awake ? layout.closeButtonSize + Design.Space.xs : 0 }

    /// A document with edits that are not saved: the row says so at its end, and the title stops before it.
    private var edited: Bool { model?.isEdited == true && renaming == nil }

    /// The mark's width with the gap on each side of it.
    private var markRoom: Double { Design.Size.editedMark + 2 * Design.Space.xs }

    /// How far the mark's centre is from the row's end (owner note n76): just before the close button while it shows; else at the
    /// end, as far from it as the icon is from the row's start, the button keeping no place.
    private func markInset(middle: Double) -> Double {
        if showsClose { return middle + layout.closeButtonSize / 2 + markRoom / 2 + awakeRoom }
        // Before the cup, which is in the close button's place.
        if awake { return middle + layout.closeButtonSize / 2 + markRoom / 2 }
        return layout.tabPaddingLeading + Design.Size.editedMark / 2
    }

    /// What the title leaves free at the row's end: the shown button's place, the mark's, both or nothing.
    private var titleEnd: Double {
        let shown = showsClose && renaming == nil
        if shown { return layout.closeButtonSize + Design.Space.xs + (edited ? markRoom : 0) + awakeRoom }
        if awake {
            // The cup in the close button's place, and the mark before it.
            return max(0, layout.tabPaddingLeading - layout.tabPaddingTrailing) + layout.closeButtonSize
                + Design.Space.xs
                + (edited ? markRoom : 0)
        }
        guard edited else { return 0 }
        return max(0, layout.tabPaddingLeading - layout.tabPaddingTrailing) + Design.Size.editedMark + Design.Space.xs
    }

    /// The title runs to the row's end; before a shown close button and before the mark it fades out over a few points.
    private var titleMask: some View {
        HStack(spacing: 0) {
            Color.black
            if titleEnd > 0 {
                LinearGradient(gradient: .eased(from: .black, to: .clear), startPoint: .leading, endPoint: .trailing)
                    .frame(width: Design.Space.m)
                // The close button sits half the row's height from its edge, a little further in on a taller row.
                Color.clear.frame(width: titleEnd)
            }
        }
    }
}
