import SunsetPane
import SwiftUI

/// What is dragged over a tile of the Pinned grid: its leading half puts it before the tile, its trailing half after; a
/// tile moves in the grid, a tab, a split or a favourite is pinned there.
enum PinnedTileDropDelegate {
    @MainActor
    static func make(
        tabs: TabsModel,
        index: Int,
        width: Double,
        active: Binding<(owner: Int, place: Bool)?>
    ) -> PlacedDropDelegate<Int, Bool> {
        PlacedDropDelegate(
            owner: index,
            accepts: { tabs.canPinDragged },
            place: { point in
                tabs.canPinDragged ? point.x > width / 2 : nil
            },
            drop: { after in
                tabs.dropDragged(in: .pinned(at: index + (after ? 1 : 0)))
            },
            active: active
        )
    }
}
