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
        rotateRows(first ... last, leftBy: n)
        blankRows(last - n + 1 ... last)
        markDirty(first ... last)
    }

    /// The rows `first...last` move down by `count`; the rows that arrive at the top are blank.
    mutating func scrollDown(from first: Int, to last: Int, by count: Int) {
        let n = min(count, last - first + 1)
        guard n > 0 else { return }
        rotateRows(first ... last, leftBy: last - first + 1 - n)
        blankRows(first ... first + n - 1)
        markDirty(first ... last)
    }

    /// Copies the top `count` screen rows into the history (the line feed that is about to push them off the screen).
    private mutating func saveToScrollback(rows count: Int) {
        for target in 0 ..< count {
            let start = grid.base(target)
            scrollback.push(grid.cells[start ..< start + columns], wrapped: grid.wrapped[Int(grid.rowMap[target])])
        }
    }

    /// Rotates the row map of a range in place (three reversals: no allocation).
    private mutating func rotateRows(_ range: ClosedRange<Int>, leftBy n: Int) {
        guard n > 0, n < range.count else { return }
        reverseRows(range.lowerBound, range.lowerBound + n - 1)
        reverseRows(range.lowerBound + n, range.upperBound)
        reverseRows(range.lowerBound, range.upperBound)
    }

    private mutating func reverseRows(_ first: Int, _ last: Int) {
        var low = first
        var high = last
        while low < high {
            grid.rowMap.swapAt(low, high)
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
