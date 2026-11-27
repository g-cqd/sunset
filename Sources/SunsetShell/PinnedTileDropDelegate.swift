import SunsetPane
import SwiftUI

/// What is dragged over a tile of the Pinned grid: its leading and trailing quarters put it before or after the tile;
/// its middle half splits in place inside the pinned tile (`TabDropAction`). When splitting is not possible (for instance,
/// dragging a multi-row selection or dragging a tile onto itself), the leading and trailing halves reorder.
enum PinnedTileDropDelegate {
    @MainActor
    static func make(
        tabs: TabsModel,
        entry: Favorites.NodeID,
        width: Double,
        active: Binding<(owner: Favorites.NodeID, place: TabDropAction)?>
    ) -> PlacedDropDelegate<Favorites.NodeID, TabDropAction> {
        PlacedDropDelegate(
            owner: entry,
            accepts: { tabs.hasDrag },
            place: { point in
                let w = max(width, 1)
                let rx = point.x / w
                let proposed: TabDropAction =
                    if rx < 0.25 {
                        .moveBefore
                    } else if rx > 0.75 {
                        .moveAfter
                    } else {
                        rx < 0.5 ? .split(.left) : .split(.right)
                    }
                if case .split = proposed, tabs.canDrop(onEntry: entry, action: proposed) {
                    return proposed
                }
                let fallback: TabDropAction = rx > 0.5 ? .moveAfter : .moveBefore
                return tabs.canDrop(onEntry: entry, action: fallback) ? fallback : nil
            },
            drop: { action in
                tabs.dropDragged(onEntry: entry, action: action)
            },
            active: active
        )
    }
}
