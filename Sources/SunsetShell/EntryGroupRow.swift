import SunsetMetrics
import SunsetPane
import SwiftUI

/// A kept entry whose panes are split (owner note n55): drawn as a split tab is in the window's list, one container with its panes as small tabs, its
/// name and icon above them when it was given any. Open, the panes show what runs in them, on a faint fill; not open, what they would start
/// from, with no fill (not dimmed). A click
/// opens and shows the entry (the row's own taps, set by `FavoritesSection`).
struct EntryGroupRow: View {
    let entry: Favorites.Entry
    let tabs: TabsModel
    let selected: Bool
    let layout: ShellSettings.Layout
    var marked = false
    @State private var hovering = false
    @Environment(\.accent) private var accent

    private var inset: Double { Design.Space.hair }
    private var panes: [PaneID] { entry.open?.panes ?? entry.home.layout.panes }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: layout.tabRadius, style: .continuous)
        VStack(alignment: .leading, spacing: inset) {
            if entry.title != nil || entry.icon != nil {
                HStack(spacing: Design.Space.xs) {
                    if let icon = entry.icon { PaneIconView(icon: icon) }
                    if let name = entry.title {
                        Text(name).font(Design.Text.detail).foregroundStyle(.secondary).lineLimit(1)
                    }
                }
                .padding(.horizontal, Design.Space.s)
            }
            HStack(spacing: inset) {
                ForEach(panes, id: \.self) { pane in
                    SidebarGroupPart(
                        model: entry.open == nil ? nil : tabs.favorites.contents[pane],
                        saved: entry.home.contents[pane],
                        lit: selected && pane == (entry.open?.focused ?? entry.home.focused),
                        layout: layout,
                        height: Design.Size.favoriteRow - 2 * inset,
                        select: { tabs.select(entry: entry.id) }
                    )
                }
            }
        }
        .padding(inset)
        .background(shape.fill(fill))
        .overlay { shape.hairline(layout).opacity(selected ? 1 : 0) }
        .contentShape(shape)
        .onHover { hovering = $0 }
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
