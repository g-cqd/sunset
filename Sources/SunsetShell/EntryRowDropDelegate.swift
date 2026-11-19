import SunsetPane
import SwiftUI

/// A tab or a kept entry dragged over a kept entry's row: the top half puts it before the row, the bottom half after.
enum EntryRowDropDelegate {
    @MainActor
    static func make(
        tabs: TabsModel,
        entry: Favorites.NodeID,
        height: Double,
        active: Binding<(owner: Favorites.NodeID, place: Bool)?>
    ) -> PlacedDropDelegate<Favorites.NodeID, Bool> {
        PlacedDropDelegate(
            owner: entry,
            accepts: { tabs.canDrop(onEntry: entry) },
            place: { point in
                tabs.canDrop(onEntry: entry) ? point.y > height / 2 : nil
            },
            drop: { after in
                tabs.dropDragged(onEntry: entry, after: after)
            },
            active: active
        )
    }
}
