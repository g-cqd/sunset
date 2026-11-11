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
        let resolved = action(at: info.location)
        defer { if active?.item == item { active = nil } }
        return tabs.dropDragged(onto: item, action: resolved)
    }

    /// A kept entry cannot be split with a tab: over a tab's row it goes before or after it, by halves.
    private func action(at location: CGPoint) -> TabDropAction {
        guard case .entry = tabs.dragged else { return TabDropAction.resolve(at: location, in: size) }
        return location.y > size.height / 2 ? .moveAfter : .moveBefore
    }

    private func update(_ info: DropInfo) {
        let action = action(at: info.location)
        if tabs.canDrop(onto: item, action: action) {
            active = (item, action)
        } else if active?.item == item {
            active = nil
        }
    }
}
