import SunsetPane
import SwiftUI

/// A tab or pane dragged over a tab row in the sidebar: the top and bottom quarters reorder before or after the row, and the
/// middle half splits with the row's tab on the left or right (`TabDropAction`, `n25`). A kept entry cannot be split with a
/// tab: over a tab's row it goes before or after it, by halves.
enum TabRowDropDelegate {
    @MainActor
    static func make(
        tabs: TabsModel,
        item: Workspace.ItemID,
        size: CGSize,
        active: Binding<(owner: Workspace.ItemID, place: TabDropAction)?>
    ) -> PlacedDropDelegate<Workspace.ItemID, TabDropAction> {
        let action: @MainActor (CGPoint) -> TabDropAction = { point in
            guard case .entry = tabs.dragged else {
                return TabDropAction.resolve(at: point, in: size)
            }
            return point.y > size.height / 2 ? .moveAfter : .moveBefore
        }
        return PlacedDropDelegate(
            owner: item,
            accepts: { tabs.hasDrag },
            place: { point in
                let resolved = action(point)
                return tabs.canDrop(onto: item, action: resolved) ? resolved : nil
            },
            drop: { resolved in
                tabs.dropDragged(onto: item, action: resolved)
            },
            active: active
        )
    }
}
