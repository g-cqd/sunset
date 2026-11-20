import SunsetMetrics
import SunsetPane
import SwiftUI

/// One tab in the sidebar (its padding, radius and close button from `layout.*`), its title faded or cut at its end. While the pointer is over it a close
/// button appears and the row is highlighted; the selected tab has a stronger highlight (dimmer in an inactive window) and the terminal card's hairline.
struct SidebarRow: View {
    @Environment(\.fadesEnds) var fadesEnds  // `appearance.ends` (n30)
    let model: (any PaneContent)?
    let selected: Bool
    var armed = false
    /// Kept true when the row slid under a close button just clicked: rapid clicks there close tabs without a move (`n27`).
    var keepCloseVisible = false
    var name: String?
    var icon: PaneIcon?
    /// What the row's pane would start from, when it is not running (a kept entry that is not open), and the command it would run.
    var saved: PaneDescriptor?
    var savedCommand: String?
    /// What its label shows of the tab.
    let parts: TabParts
    let layout: ShellSettings.Layout
    /// What the button at the row's end does: close a tab, unload a kept entry, delete one that is not open, close an open document.
    var button = Button.close
    /// Open (every tab, an open kept entry): a faint fill at rest; a kept entry not open has none, and is not dimmed.
    var open = true
    /// A row of the Favorites tree: one line is `Design.Size.favoriteRow` tall instead of `tabRow`.
    var compact = false
    /// One of several rows selected together (R3 step d): in the accent; stronger when it is also the shown row.
    var marked = false
    /// It keeps the Mac awake (roadmap 0035 E): a cup after its title. Lets it sleep again: the cup, pointed at (note n5).
    var awake = false
    var stopAwake: (() -> Void)?
    /// While its name is edited in place: the field's first text, and what to do with the result (nil: Escape, nothing changes).
    var renaming: (start: String, done: (String?) -> Void)?
    let close: () -> Void

    enum Button {
        case close, unload, delete

        var symbol: String {
            self == .unload ? "minus" : "xmark"
        }
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
    @Environment(\.siteTint) private var siteTint

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: layout.tabRadius, style: .continuous)
        return HStack(spacing: Design.Space.xs) {
            if let renaming {
                // The row is the field: its picture stays, the text is where the title was (note n4).
                HStack(spacing: GlyphSpacing.toText) {
                    if parts.icon {
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
                    parts: parts,
                    showEdited: false,
                    showControls: false,
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
                let end = rowEnd(closeShown: showsClose)
                if edited { EditedMark().position(x: proxy.size.width - end.markInset(middle: middle), y: middle) }
                ForEach(Array(endControls.enumerated()), id: \.element) { index, control in
                    endControl(control).position(x: proxy.size.width - end.inset(of: index, middle: middle), y: middle)
                }
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
        .keptHover($hovering)
        .animation(layout.smooth, value: hovering)
        .animation(layout.smooth, value: overClose)
        .animation(layout.smooth, value: selected)
        .animation(layout.smooth, value: armed)
        .animation(layout.smooth, value: activeState)
    }

    /// Hover and selection variants of the highlight.
    private var highlight: Color {
        if armed { return .red.opacity(RowFill.armed(hovering: hovering || keepCloseVisible)) }
        if let fill = RowFill.marked(RowEmphasis.of(shown: selected, marked: marked), hovering: hovering) {
            return accent.color.opacity(fill)
        }
        if let tint = RowFill.siteTint(
            siteTint,
            selected: selected,
            hovering: hovering || keepCloseVisible,
            color: model?.siteColor
        ) {
            return tint.color
        }
        let fill = RowFill.opacity(
            selected: selected,
            hovering: hovering || keepCloseVisible,
            inactive: activeState == .inactive,
            open: open
        )
        return fill == 0 ? .clear : .primary.opacity(fill)
    }

    /// Two lines when the directory (or a page's address) is shown and there is one.
    private var lines: Int {
        parts.directory && (model?.detail ?? saved?.directory) != nil ? 2 : 1
    }

    /// Over the row's end, so that the title has the whole width while it is hidden (owner note n65); shown, the title fades out under it.
    private var closeButton: some View {
        SwiftUI.Button(action: close) {
            RowButtonFace(
                symbol: button.symbol,
                side: layout.closeButtonSize,
                radius: layout.closeButtonRadius,
                armed: armed,
                over: overClose
            )
        }
        .buttonStyle(.plain)
        .opacity(showsClose ? 1 : 0)
        .allowsHitTesting(showsClose)
        .keptHover($overClose)
        .help(armed ? "Click again to close running command" : button.help)
    }

    var showsClose: Bool {
        hovering || armed || keepCloseVisible
    }

    /// The title runs to the row's end; before a shown close button and before the mark it fades out over a few points.
    private var titleMask: some View {
        HStack(spacing: 0) {
            Color.black
            if titleEnd > 0 {
                LinearGradient(
                    gradient: .end(from: .black, to: .clear, fading: fadesEnds),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: Design.Space.m)
                // The close button sits half the row's height from its edge, a little further in on a taller row.
                Color.clear.frame(width: titleEnd)
            }
        }
    }
}
