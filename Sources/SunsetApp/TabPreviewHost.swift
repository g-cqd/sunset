import SunsetConfig
import SunsetPane
import SunsetRuntime
import SunsetShell
import SunsetShellBridge
import SunsetTerminal
import SwiftUI

/// The one preview card of a window: it comes in beside the row under the pointer, glides to the next row the pointer goes to
/// while its content changes, stays open while the pointer hovers the card itself, and goes a moment after the pointer leaves
/// both the rows and the card. Clicking the preview card selects that tab or toggles the folder.
struct TabPreviewHost: View {
    @Environment(\.runtime) var runtime

    let tabs: TabsModel
    let layout: Configuration.Layout
    /// The pane area, in the window.
    let area: CGRect
    let sidebarOnRight: Bool
    /// Which rows show a card (`sidebar.previews` and the kinds).
    var kinds = PreviewKinds()

    /// What the card shows: it stays a moment after the pointer left its row, so that going from a row to the next (or onto the card) moves or keeps it.
    @State private var shown: Shown?
    @State private var leaving: Task<Void, Never>?

    /// A tab's card, or a folder's.
    struct Shown: Equatable {
        var item: Workspace.ItemID?
        var folder: Favorites.NodeID?
        var row: CGRect?
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            if let shown, let id = shown.item, let item = tabs.previewItem(id) {
                let card = TabPreviewCard(item: item, tabs: tabs, layout: layout)
                placed(
                    card,
                    size: CGSize(
                        width: TabPreviewCard.width + 2 * Design.Space.s,
                        height: card.height + Design.Preview.chrome
                    ),
                    row: shown.row
                ) {
                    tabs.hoveredPreview = false
                    selectPreviewedItem(id)
                }
            } else if let shown, let id = shown.folder, let folder = tabs.favorites.favorites.folder(id) {
                let card = FolderPreviewCard(folder: folder, kept: tabs.favorites, layout: ShellSettings.Layout(layout))
                placed(card, size: CGSize(width: FolderPreviewCard.width, height: card.height), row: shown.row) {
                    tabs.favorites.edit { $0.setCollapsed(!folder.isCollapsed, for: folder.id) }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .animation(Design.Preview.glide, value: shown)
        .onChange(of: tabs.hoveredItem, initial: true) { _, _ in follow() }
        .onChange(of: tabs.hoveredFolder) { _, _ in follow() }
        .onChange(of: tabs.hoveredPreview) { _, _ in follow() }
        .onChange(of: tabs.hoveredRowFrame) { _, _ in follow() }
        .onChange(of: tabs.dragged == nil) { _, _ in follow() }
        .onChange(of: kinds) { _, _ in follow() }
        // A page's snapshot taken as the pointer came arrives a moment later.
        .onChange(of: hoveredHasPicture) { _, _ in follow() }
        .onDisappear { tabs.hoveredPreview = false }
    }

    private func selectPreviewedItem(_ id: Workspace.ItemID) {
        if tabs.workspace.items.contains(where: { $0.id == id }) {
            tabs.select(item: id)
            return
        }
        for keeper in [tabs.favorites, tabs.pinned].compactMap({ $0 }) {
            if let entry = keeper.favorites.entries.first(where: { $0.open?.id == id }) {
                tabs.select(entry: entry.id)
                return
            }
        }
    }

    /// A card beside the row it is about, interactive only over the card's own rect so hovering the card holds it and the
    /// floating sidebar open while clicks elsewhere pass straight through to the pane area.
    private func placed(
        _ card: some View,
        size: CGSize,
        row: CGRect?,
        onTap: @escaping () -> Void
    ) -> some View {
        let origin = PreviewPlacement.origin(
            size: size,
            row: row,
            area: area,
            sidebarOnRight: sidebarOnRight,
            panel: tabs.sidebarFrame
        )
        return ZStack(alignment: .topLeading) {
            card
                .contentShape(.rect)
                .onHover { inside in tabs.hoveredPreview = inside }
                .onTapGesture(perform: onTap)
                .offset(x: origin.x, y: origin.y)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .transition(.opacity.combined(with: .scale(scale: Design.Preview.inScale, anchor: rowAnchor(row))))
    }

    /// Whether the panes of the tab under the pointer have a picture to show: a terminal's last frame, a page's snapshot.
    private var hoveredHasPicture: Bool {
        guard let id = tabs.hoveredItem, let item = tabs.previewItem(id) else {
            return false
        }
        return item.panes.contains { tabs.terminal($0)?.lastSurface != nil || tabs.content($0)?.picture != nil }
    }

    /// The point of the area nearest the row's middle, as a unit point of the area: where the card comes from.
    private func rowAnchor(_ row: CGRect?) -> UnitPoint {
        guard let row, area.width > 0, area.height > 0 else { return sidebarOnRight ? .trailing : .leading }
        let x = min(max(row.midX - area.minX, 0), area.width)
        let y = min(max(row.midY - area.minY, 0), area.height)
        return UnitPoint(x: x / area.width, y: y / area.height)
    }

    /// How old a hidden page's picture may be before its preview is made again.
    static let pictureAge = Duration.seconds(30)

    /// Takes the row under the pointer when its tab has something to show; stays while the pointer is on the card; leaves a moment after there is none.
    private func follow() {
        guard tabs.dragged == nil else {
            leaving?.cancel()
            tabs.hoveredPreview = false
            shown = nil
            return
        }
        if let id = tabs.hoveredItem, let item = tabs.previewItem(id) {
            for pane in item.panes { tabs.content(pane)?.refreshPicture(olderThan: Self.pictureAge) }
        }
        if let id = tabs.hoveredItem, id != tabs.shownItem?.id, let item = tabs.previewItem(id),
            kinds.shows(
                kinds: item.panes.map { tabs.content($0)?.descriptor.kind ?? tabs.pendingDescriptor($0)?.kind ?? "" }
            )
        {
            leaving?.cancel()
            shown = Shown(item: id, row: tabs.hoveredRowFrame)
        } else if let folder = tabs.hoveredFolder, kinds.showsFolders {
            leaving?.cancel()
            shown = Shown(folder: folder, row: tabs.hoveredRowFrame)
        } else if tabs.hoveredPreview, shown != nil {
            // Pointer moved from the sidebar row onto the preview card itself: hold the card and the sidebar!
            leaving?.cancel()
        } else {
            leaving?.cancel()
            leaving = runtime.task {
                await runtime.sleep(for: Design.Preview.linger)
                if !Task.isCancelled, !tabs.hoveredPreview {
                    shown = nil
                }
            }
        }
    }
}
