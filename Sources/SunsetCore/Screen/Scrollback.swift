/// Lines that left the top of the primary screen, oldest first, in a ring of at most `limit` lines of `columns` cells.
struct Scrollback: Sendable {
    let columns: Int
    let limit: Int
    private var cells = ContiguousArray<Cell>()
    private var wrapped = ContiguousArray<Bool>()
    private var start = 0
    private(set) var count = 0

    init(columns: Int, limit: Int) {
        self.columns = columns
        self.limit = max(0, limit)
    }

    subscript(line: Int, column: Int) -> Cell { cells[physical(line) * columns + column] }

    func isWrapped(_ line: Int) -> Bool { wrapped[physical(line)] }

    private func physical(_ line: Int) -> Int { (start + line) % max(count, 1) }

    /// Adds a line at the newest end, dropping the oldest when full.
    mutating func push(_ line: ArraySlice<Cell>, wrapped isWrapped: Bool) {
        guard limit > 0 else { return }
        precondition(line.count == columns, "a scrollback line is as wide as the screen was")
        if count < limit {
            // Not full: start is 0 and the storage is in order.
            cells.append(contentsOf: line)
            wrapped.append(isWrapped)
            count += 1
        } else {
            let slot = start
            let base = slot * columns
            cells.replaceSubrange(base ..< base + columns, with: line)
            wrapped[slot] = isWrapped
            start = (start + 1) % count
        }
    }

    mutating func removeAll() {
        cells.removeAll(keepingCapacity: true)
        wrapped.removeAll(keepingCapacity: true)
        start = 0
        count = 0
    }

    /// Rewrites every cell's style id, newest line first (style table compaction: when the table cannot hold every style, the oldest lines are the ones
    /// that lose theirs).
    mutating func mapStyles(_ map: (UInt16) -> UInt16) {
        var line = count - 1
        while line >= 0 {
            let base = physical(line) * columns
            for column in 0 ..< columns {
                cells[base + column] = cells[base + column].withStyle(map(cells[base + column].styleID))
            }
            line -= 1
        }
    }
}
