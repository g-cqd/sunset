import SunsetPane
import SwiftUI

/// Receives a tab or pane dragged over a tab row in the sidebar: the top and bottom quarters reorder before or after the row, and the middle half splits
/// with the row's tab on the left or right (`TabDropAction`, `n25`).
struct TabRowDropDelegate: DropDelegate {
    let tabs: TabsModel
    let item: Workspace.ItemID
    let size: CGSize
    @Binding var active: (item: Workspace.ItemID, action: TabDropAction)?

    func validateDrop(info: DropInfo) -> Bool { tabs.dragged != nil }

    func dropEntered(info: DropInfo) { update(info) }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        update(info)
        return DropProposal(operation: active?.item == item ? .move : .cancel)
    }

    func dropExited(info: DropInfo) {
        if active?.item == item { active = nil }
    }

    func performDrop(info: DropInfo) -> Bool {
        let resolved = TabDropAction.resolve(at: info.location, in: size)
        defer { if active?.item == item { active = nil } }
        return tabs.dropDragged(onto: item, action: resolved)
    }

    private func update(_ info: DropInfo) {
        let action = TabDropAction.resolve(at: info.location, in: size)
        if tabs.canDrop(onto: item, action: action) {
            active = (item, action)
        } else if active?.item == item {
            active = nil
        }
    }
}
