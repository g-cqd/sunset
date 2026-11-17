import SunsetConfig
import SunsetPane
import SunsetShell
import SunsetTerminal
import SwiftUI

/// The one preview card of a window (owner, 2026-11-13, t229): it comes in beside the row under the pointer, glides to the next row
/// the pointer goes to while its content changes, and goes a moment after the pointer left the rows. For the selected tab too.
/// Beside a sidebar's row, level with it; for a row of the built-in bar, above or below it (`PreviewPlacement`).
struct TabPreviewHost: View {
    let tabs: TabsModel
    let layout: Configuration.Layout
    /// The pane area, in the window.
    let area: CGRect
    let sidebarOnRight: Bool

    /// What the card shows: it stays a moment after the pointer left its row, so that going from a row to the next moves it.
    @State private var shown: Shown?
    @State private var leaving: Task<Void, Never>?

    struct Shown: Equatable {
        var item: Workspace.ItemID
        var row: CGRect?
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            if let shown, let item = tabs.previewItem(shown.item) {
                let card = TabPreviewCard(item: item, tabs: tabs, layout: layout)
                let size = CGSize(
                    width: TabPreviewCard.width + 2 * Design.Space.s,
                    height: card.height + Design.Preview.chrome
                )
                let origin = PreviewPlacement.origin(
                    size: size,
                    row: shown.row,
                    area: area,
                    sidebarOnRight: sidebarOnRight
                )
                // In an area-sized frame, so that the transition's anchor is a point of the area: the card grows out of its
                // tab's row and shrinks back into it (owner, 2026-11-13), not from the card's or the window's middle.
                ZStack(alignment: .topLeading) { card.offset(x: origin.x, y: origin.y) }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .transition(
                        .opacity.combined(with: .scale(scale: Design.Preview.inScale, anchor: rowAnchor(shown.row)))
                    )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .allowsHitTesting(false)
        .animation(Design.Preview.glide, value: shown)
        .onChange(of: tabs.hoveredItem, initial: true) { _, _ in follow() }
        .onChange(of: tabs.hoveredRowFrame) { _, _ in follow() }
        .onChange(of: tabs.dragged == nil) { _, _ in follow() }
        // A page's snapshot taken as the pointer came arrives a moment later (roadmap 0035 C).
        .onChange(of: hoveredHasPicture) { _, _ in follow() }
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

    /// Takes the row under the pointer when its tab has something to show; leaves a moment after there is none.
    private func follow() {
        guard tabs.dragged == nil else {
            leaving?.cancel()
            shown = nil
            return
        }
        if let id = tabs.hoveredItem, let item = tabs.previewItem(id) {
            // A page on screen is pictured as it is now; one that is hidden keeps the picture taken as it was hidden.
            for pane in item.panes { tabs.content(pane)?.takePicture() }
        }
        if hoveredHasPicture, let id = tabs.hoveredItem {
            leaving?.cancel()
            shown = Shown(item: id, row: tabs.hoveredRowFrame)
        } else {
            leaving?.cancel()
            leaving = Task {
                try? await Task.sleep(for: Design.Preview.linger)
                if !Task.isCancelled { shown = nil }
            }
        }
    }
}
