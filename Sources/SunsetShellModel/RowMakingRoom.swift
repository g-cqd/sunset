package import CoreGraphics
package import SunsetPane

/// How far a tab's row moves aside while a tab is dragged over the list ("tabs move around to make room where the
/// dragged one goes"): the row a drop would go before moves down, the one it would go after moves up, each by half the
/// room; nothing for a split, nothing for the others.
package enum RowMakingRoom {
    /// The vertical offset of the row `row` for a drop `action` on `owner`, making `room` points between two rows.
    package static func offset<ID: Equatable>(
        of row: ID,
        rows: [ID],
        owner: ID,
        action: TabDropAction,
        room: CGFloat
    )
        -> CGFloat
    {
        guard let at = rows.firstIndex(of: owner), let index = rows.firstIndex(of: row) else { return 0 }
        // The gap the drop opens: between `above` and `above + 1`.
        let above: Int
        switch action {
            case .moveBefore: above = at - 1
            case .moveAfter: above = at
            case .split: return 0
        }
        if index == above { return -room / 2 }
        if index == above + 1 { return room / 2 }
        return 0
    }

    /// The same for a drag over the gap `gap` (a drop before the row under it) or, when over none, a drop `drop` on a row.
    package static func offset<ID: Equatable>(
        of row: ID,
        rows: [ID],
        gap: Int?,
        drop: (owner: ID, place: TabDropAction)?,
        room: CGFloat
    ) -> CGFloat {
        let overGap = gap.flatMap { index in
            rows.indices.contains(index) ? (rows[index], TabDropAction.moveBefore) : nil
        }
        guard let (owner, action) = overGap ?? drop.map({ ($0.owner, $0.place) }) else { return 0 }
        return offset(of: row, rows: rows, owner: owner, action: action, room: room)
    }
}
