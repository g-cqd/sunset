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
        if saveHistory, first == 0, !isAlternate { saveToScrollback(rows: n) }
        Self.rotate(&grid.rowMap, first ... last, leftBy: n)
        blankRows(last - n + 1 ... last)
        markDirty(last - n + 1 ... last)
    }

    /// The rows `first...last` move down by `count`; the rows that arrive at the top are blank.
    mutating func scrollDown(from first: Int, to last: Int, by count: Int) {
        let n = min(count, last - first + 1)
        guard n > 0 else { return }
        Self.rotate(&grid.rowMap, first ... last, leftBy: last - first + 1 - n)
        blankRows(first ... first + n - 1)
        markDirty(first ... first + n - 1)
    }

    /// Copies the top `count` screen rows into the history (the line feed that is about to push them off the screen).
    private mutating func saveToScrollback(rows count: Int) {
        for target in 0 ..< count {
            // Only the cells that can be other than empty (`Grid.used`): the history trims the blanks anyway.
            let start = grid.base(target)
            scrollback.push(
                grid.cells[start ..< start + grid.usedCount(row: target)],
                wrapped: grid.wrapped[Int(grid.rowMap[target])]
            )
        }
    }

    /// Rotates a range of a per-row array in place: one line (the common scroll) moves the rest down with a single copy; more take three reversals. Both
    /// work on the buffer itself, so a scroll does not pay for a uniqueness check and a bounds check per row.
    private static func rotate(_ rows: inout ContiguousArray<Int32>, _ range: ClosedRange<Int>, leftBy n: Int) {
        guard n > 0, n < range.count else { return }
        rows.withUnsafeMutableBufferPointer { map in
            guard let start = map.baseAddress.map({ $0 + range.lowerBound }) else { return }
            let count = range.count
            if n == 1 {
                let first = start.pointee
                start.update(from: start + 1, count: count - 1)
                (start + count - 1).pointee = first
                return
            }
            Self.reverse(start, 0, n - 1)
            Self.reverse(start, n, count - 1)
            Self.reverse(start, 0, count - 1)
        }
    }

    private static func reverse(_ start: UnsafeMutablePointer<Int32>, _ first: Int, _ last: Int) {
        var low = first
        var high = last
        while low < high {
            swap(&start[low], &start[high])
            low += 1
            high -= 1
        }
    }

    private mutating func blankRows(_ rows: ClosedRange<Int>) {
        let blank = Cell(scalar: 0, width: .narrow, style: currentEraseID())
        for row in rows {
            grid.fill(row: row, from: 0, to: columns - 1, with: blank)
            grid.wrapped[Int(grid.rowMap[row])] = false
        }
    }
}
