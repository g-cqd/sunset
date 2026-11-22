import SunsetPane
import SwiftUI

/// A tab, a pane or a kept entry dragged over a tab's or a favorite's row: the top and bottom quarters put it before or
/// after the row, the middle half splits with the row on the left or right (`TabDropAction`). What cannot split with
/// the row (a pinned tile, a tab on itself) goes before or after it, by halves.
enum RowDropDelegate {
    @MainActor
    static func make<Owner: Equatable>(
        owner: Owner,
        size: CGSize,
        active: Binding<(owner: Owner, place: TabDropAction)?>,
        accepts: @escaping @MainActor () -> Bool,
        can: @escaping @MainActor (TabDropAction) -> Bool,
        drop: @escaping @MainActor (TabDropAction) -> Bool
    ) -> PlacedDropDelegate<Owner, TabDropAction> {
        PlacedDropDelegate(
            owner: owner,
            accepts: accepts,
            place: { point in
                let resolved = TabDropAction.resolve(at: point, in: size)
                if case .split = resolved, can(resolved) { return resolved }
                let halves: TabDropAction =
                    if case .split = resolved { point.y > size.height / 2 ? .moveAfter : .moveBefore } else { resolved }
                return can(halves) ? halves : nil
            },
            drop: drop,
            active: active
        )
    }
}
