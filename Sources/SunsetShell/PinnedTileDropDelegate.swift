import SunsetPane
import SwiftUI

/// Receives what is dragged over a tile of the Pinned grid (roadmap 0035 A): its leading half puts it before the tile, its
/// trailing half after; a tile moves in the grid, a tab, a split or a favourite is pinned there.
struct PinnedTileDropDelegate: DropDelegate {
    let tabs: TabsModel
    /// The tile's place in the grid.
    let index: Int
    let width: Double
    @Binding var active: (index: Int, after: Bool)?

    private func place(_ info: DropInfo) -> (index: Int, after: Bool) { (index, info.location.x > width / 2) }

    func validateDrop(info: DropInfo) -> Bool { tabs.canPinDragged }

    func dropEntered(info: DropInfo) { update(info) }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        update(info)
        return DropProposal(operation: active?.index == index ? .move : .cancel)
    }

    func dropExited(info: DropInfo) {
        if active?.index == index { active = nil }
    }

    func performDrop(info: DropInfo) -> Bool {
        let place = place(info)
        defer { if active?.index == index { active = nil } }
        return tabs.dropDragged(in: .pinned(at: place.index + (place.after ? 1 : 0)))
    }

    private func update(_ info: DropInfo) {
        if tabs.canPinDragged {
            active = place(info)
        } else if active?.index == index {
            active = nil
        }
    }
}
