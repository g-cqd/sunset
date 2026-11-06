/// Lines that left the top of the primary screen, oldest first, at most `limit` of them, `columns` cells each.
///
/// The lines live in chunks of `chunkLines`. A copy of the history (a snapshot of the screen for the renderer) shares every chunk with the original, and
/// writing to the original copies only the newest chunk, never the whole history: with one flat array every snapshot made the next line copy up to
/// 100 000 lines (measured: 42 times the instructions of a flood without snapshots). The oldest chunk is released as soon as all of its lines are gone, so
/// the memory held is at most `limit` plus one chunk.
struct Scrollback: Sendable {
    static let chunkLines = 128

    private struct Chunk: Sendable {
        var cells = ContiguousArray<Cell>()
        var wrapped = ContiguousArray<Bool>()
    }

    let columns: Int
    let limit: Int
    private var chunks: [Chunk] = []
    /// The chunk released last, emptied and kept for the next one: a history that is full and rolling allocates nothing.
    private var spare: Chunk?
    /// Lines of the first chunk that are gone already.
    private var head = 0
    private(set) var count = 0
    /// How many lines have left the history so far (dropped when it was full, or cleared): with a line's index it makes a number that does not change while
    /// the history rolls (`PromptMark`).
    var evicted = 0

    init(columns: Int, limit: Int) {
        self.columns = columns
        self.limit = max(0, limit)
    }

    /// Lines held in memory, the ones past the limit that are not yet released included.
    var storedLines: Int { chunks.reduce(0) { $0 + $1.wrapped.count } }

    subscript(line: Int, column: Int) -> Cell {
        let (chunk, index) = locate(line)
        return chunks[chunk].cells[index * columns + column]
    }

    func isWrapped(_ line: Int) -> Bool {
        let (chunk, index) = locate(line)
        return chunks[chunk].wrapped[index]
    }

    private func locate(_ line: Int) -> (chunk: Int, index: Int) {
        let absolute = head + line
        return (absolute / Self.chunkLines, absolute % Self.chunkLines)
    }

    /// Whether the chunk that holds `line` is stored in memory shared with a chunk of `other` (a copy not written to since): a copy must not pay for the lines.
    func sharesStorage(line: Int, with other: Scrollback) -> Bool {
        let (chunk, _) = locate(line)
        let address = chunks[chunk].cells.withUnsafeBufferPointer { $0.baseAddress }
        return other.chunks.contains { $0.cells.withUnsafeBufferPointer { $0.baseAddress } == address }
    }

    /// Adds a line at the newest end, dropping the oldest when full.
    mutating func push(_ line: ArraySlice<Cell>, wrapped isWrapped: Bool) {
        guard limit > 0 else {
            evicted += 1
            return
        }
        precondition(line.count == columns, "a scrollback line is as wide as the screen was")
        if count == limit { dropOldest() }
        if chunks.last.map({ $0.wrapped.count == Self.chunkLines }) ?? true {
            var fresh = spare ?? Chunk()
            spare = nil
            fresh.cells.reserveCapacity(Self.chunkLines * columns)
            fresh.wrapped.reserveCapacity(Self.chunkLines)
            chunks.append(fresh)
        }
        chunks[chunks.count - 1].cells.append(contentsOf: line)
        chunks[chunks.count - 1].wrapped.append(isWrapped)
        count += 1
    }

    private mutating func dropOldest() {
        head += 1
        count -= 1
        evicted += 1
        if head == Self.chunkLines {
            var released = chunks.removeFirst()
            released.cells.removeAll(keepingCapacity: true)
            released.wrapped.removeAll(keepingCapacity: true)
            spare = released
            head = 0
        }
    }

    mutating func removeAll() {
        evicted += count
        chunks.removeAll()
        spare = nil
        head = 0
        count = 0
    }

    /// Rewrites every cell's style id, newest line first (style table compaction: when the table cannot hold every style, the oldest lines are the ones
    /// that lose theirs).
    mutating func mapStyles(_ map: (UInt16) -> UInt16) {
        var line = count - 1
        while line >= 0 {
            let (chunk, index) = locate(line)
            let base = index * columns
            for column in 0 ..< columns {
                let cell = chunks[chunk].cells[base + column]
                chunks[chunk].cells[base + column] = cell.withStyle(map(cell.styleID))
            }
            line -= 1
        }
    }
}
