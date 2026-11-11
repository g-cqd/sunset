import SunsetPane
import SwiftUI

/// Receives a tab or a kept entry dragged over a kept entry's row: the top half puts it before the row, the bottom half after.
struct EntryRowDropDelegate: DropDelegate {
    let tabs: TabsModel
    let entry: Favorites.NodeID
    let height: Double
    @Binding var active: (entry: Favorites.NodeID, after: Bool)?

    func validateDrop(info: DropInfo) -> Bool { tabs.canDrop(onEntry: entry) }

    func dropEntered(info: DropInfo) { update(info) }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        update(info)
        return DropProposal(operation: active?.entry == entry ? .move : .cancel)
    }

    func dropExited(info: DropInfo) {
        if active?.entry == entry { active = nil }
    }

    func performDrop(info: DropInfo) -> Bool {
        defer { if active?.entry == entry { active = nil } }
        return tabs.dropDragged(onEntry: entry, after: info.location.y > height / 2)
    }

    private func update(_ info: DropInfo) {
        active = tabs.canDrop(onEntry: entry) ? (entry, info.location.y > height / 2) : nil
    }
}
