/// Scrolling a range of rows: the row numbers move, the rows that arrive are blanked.
extension Grid {
    /// The rows of `range` move up by `count`; the rows that arrive at the bottom are filled with `blank` and are not wrapped.
    @inline(__always) mutating func scrollUp(_ range: ClosedRange<Int>, by count: Int, blank: Cell) {
        let n = min(count, range.count)
        guard n > 0 else { return }
        if n == 1 {
            scrollOne(range, up: true, blank: blank)
        } else {
            rotate(range, leftBy: n)
            for row in range.upperBound - n + 1 ... range.upperBound { blankRow(row, blank) }
        }
    }

    /// The rows of `range` move down by `count`; the rows that arrive at the top are filled with `blank` and are not wrapped.
    mutating func scrollDown(_ range: ClosedRange<Int>, by count: Int, blank: Cell) {
        let n = min(count, range.count)
        guard n > 0 else { return }
        if n == 1 {
            scrollOne(range, up: false, blank: blank)
        } else {
            rotate(range, leftBy: range.count - n)
            for row in range.lowerBound ... range.lowerBound + n - 1 { blankRow(row, blank) }
        }
    }

    private mutating func blankRow(_ row: Int, _ blank: Cell) {
        fill(row: row, from: 0, to: columns - 1, with: blank)
        setWrapped(row: row, false)
    }

    /// One line, the common scroll: the row map, the count and the wrap of the row that arrives are written in one access to `meta`, and its cells are
    /// touched only where it held something (an empty blank) or wholly (a coloured one).
    @inline(__always) private mutating func scrollOne(_ range: ClosedRange<Int>, up: Bool, blank: Cell) {
        let rows = rows
        let columns = columns
        let first = range.lowerBound
        let last = range.upperBound
        var physical = 0
        var held = 0
        meta.withUnsafeMutableBufferPointer { meta in
            guard let map = meta.baseAddress else { return }
            // One move of the row numbers between (the two ranges overlap: `update` moves as `memmove` does), not a loop over them.
            if up {
                let moved = meta[first]
                unsafe (map + first).update(from: map + first + 1, count: last - first)
                meta[last] = moved
                physical = Int(moved)
            } else {
                let moved = meta[last]
                unsafe (map + first + 1).update(from: map + first, count: last - first)
                meta[first] = moved
                physical = Int(moved)
            }
            held = Int(meta[rows + physical])
            meta[rows + physical] = blank.raw == 0 ? 0 : Int32(columns)
            meta[2 * rows + physical] = 0
        }
        let count = blank.raw == 0 ? held : columns
        if count > 0 { fillCells(physical: physical, from: 0, count: count, with: blank) }
    }

    /// Rotates the row map over `range`, by three reversals in place.
    private mutating func rotate(_ range: ClosedRange<Int>, leftBy n: Int) {
        guard n > 0, n < range.count else { return }
        let first = range.lowerBound
        let last = range.upperBound
        meta.withUnsafeMutableBufferPointer { meta in
            Self.reverse(&meta, first, first + n - 1)
            Self.reverse(&meta, first + n, last)
            Self.reverse(&meta, first, last)
        }
    }

    private static func reverse(_ meta: inout UnsafeMutableBufferPointer<Int32>, _ first: Int, _ last: Int) {
        var low = first
        var high = last
        while low < high {
            meta.swapAt(low, high)
            low += 1
            high -= 1
        }
    }
}
