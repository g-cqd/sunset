import SunsetMetrics
import SunsetPane
import SwiftUI

/// A kept entry whose panes are split: drawn as a split tab is in the window's list, one container with its panes as small tabs, its name
/// and icon above them when it was given any. Open, the panes show what runs in them, on a faint fill; not open, what they would start
/// from, with no fill (not dimmed). A click opens and shows the entry (the row's own taps, set by `FavoritesSection`).
struct EntryGroupRow: View {
    let entry: Favorites.Entry
    let tabs: TabsModel
    let selected: Bool
    let layout: ShellSettings.Layout
    var marked = false
    @State private var hovering = false
    @Environment(\.accent) private var accent

    private var inset: Double {
        GroupFrame<EmptyView, EmptyView>.inset
    }
    private var panes: [PaneID] {
        entry.open?.panes ?? entry.home.layout.panes
    }

    var body: some View {
        GroupFrame(name: entry.title, icon: entry.icon, layout: layout, fill: fill) {
            ForEach(panes, id: \.self) { pane in
                SidebarGroupPart(
                    model: entry.open == nil ? nil : tabs.content(pane),
                    saved: entry.home.contents[pane],
                    lit: selected && pane == (entry.open?.focused ?? entry.home.focused),
                    layout: layout,
                    height: Design.Size.favoriteRow - 2 * inset,
                    // Open: shows the entry with the keyboard in that pane; not loaded, opens it.
                    select: {
                        if entry.isOpen {
                            tabs.choose(part: pane, of: .node(entry.id))
                        } else {
                            tabs.select(entry: entry.id)
                        }
                    }
                )
                .contextMenu {
                    if entry.isOpen, panes.count > 1 {
                        Button("Move Pane to Its Own Tab") { tabs.separate(pane: pane) }
                    }
                }
            }
        } outline: { shape in
            shape.hairline(layout).opacity(selected ? 1 : 0)
        }
        .keptHover($hovering)
        .animation(layout.smooth, value: hovering)
        .animation(layout.smooth, value: selected)
    }

    private var fill: Color {
        if marked { return accent.color.opacity(Design.Fill.target) }
        if selected { return .primary.opacity(Design.Fill.openHover) }
        if entry.isOpen { return .primary.opacity(hovering ? Design.Fill.openHover : Design.Fill.open) }
        return .primary.opacity(hovering ? Design.Fill.hover : 0)
    }
}
