extension Screen {
    /// Moves down one line; at the bottom of the scroll region the region scrolls up instead. Below the region the cursor stops at the last row.
    mutating func lineFeed() {
        pendingWrap = false
        if row == bottom {
            scrollUp(from: top, to: bottom, by: 1, saveHistory: true)
        } else if row < rows - 1 {
            row += 1
        }
        if modes.newLine { column = 0 }
    }

    mutating func reverseIndex() {
        pendingWrap = false
        if row == top {
            scrollDown(from: top, to: bottom, by: 1)
        } else if row > 0 {
            row -= 1
        }
    }

    /// The rows `first...last` move up by `count`; the rows that arrive at the bottom are blank.
    mutating func scrollUp(from first: Int, to last: Int, by count: Int, saveHistory: Bool = false) {
        let n = min(count, last - first + 1)
        guard n > 0 else { return }
        if saveHistory, first == 0, !isAlternate { Self.save(rows: n, of: grid, into: &scrollback) }
        grid.scrollUp(first ... last, by: n, blank: Cell(scalar: 0, width: .narrow, style: currentEraseID()))
        markDirty(last - n + 1 ... last)
    }

    /// The rows `first...last` move down by `count`; the rows that arrive at the top are blank.
    mutating func scrollDown(from first: Int, to last: Int, by count: Int) {
        let n = min(count, last - first + 1)
        guard n > 0 else { return }
        grid.scrollDown(first ... last, by: n, blank: Cell(scalar: 0, width: .narrow, style: currentEraseID()))
        markDirty(first ... first + n - 1)
    }

    /// Copies the top `count` screen rows into the history (the line feed that is about to push them off the screen). The grid is read and the history
    /// written as two things, not through `self`: the cells are reached where they are, with no copy of the array's reference.
    private static func save(rows count: Int, of grid: borrowing Grid, into history: inout Scrollback) {
        grid.cells.withUnsafeBufferPointer { cells in
            for target in 0 ..< count {
                // Only the cells that can be other than empty (`Grid.used`): the history trims the blanks anyway.
                let start = grid.base(target)
                history.push(
                    cells: UnsafeBufferPointer(rebasing: cells[start ..< start + grid.usedCount(row: target)]),
                    wrapped: grid.isWrapped(row: target)
                )
            }
        }
    }
}
