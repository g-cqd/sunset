/// Lines that left the top of the primary screen, oldest first, at most `limit` of them, `columns` cells each.
///
/// The lines live in chunks of `chunkLines`. A copy of the history (a snapshot of the screen for the renderer) shares every chunk with the original, and
/// writing to the original copies only the newest chunk, never the whole history: with one flat array every snapshot made the next line copy up to
/// 100 000 lines (measured: 42 times the instructions of a flood without snapshots). The oldest chunk is released as soon as all of its lines are gone, so
/// the memory held is at most `limit` plus one chunk.
struct Scrollback: Sendable {
    static let chunkLines = 128

    /// A line is kept without its trailing blank cells (see `push`): `ends[i]` is where line `i` ends in `cells` (it starts where line `i - 1` ended), and
    /// the top bit says that the line continues on the next (it wrapped): one array to append to per line instead of two.
    struct Chunk: Sendable {
        var cells = ContiguousArray<Cell>()
        var ends = ContiguousArray<UInt32>()
        /// The cells in packed form (`cells` is then empty): see `Scrollback+Packing`.
        var packed: PackedCells?

        func cell(at index: Int) -> Cell { packed?.cell(at: index) ?? cells[index] }

        /// Adds a line: its cells (without the trailing blanks) and where it ends. One access to the chunk for both; a short line is appended cell by cell
        /// (the bulk append's set-up, a `memmove` call included, cost more than the copy for a line of a few cells).
        mutating func append(_ line: UnsafeBufferPointer<Cell>, wrapped: Bool) {
            if line.count <= 8 {
                for cell in line { cells.append(cell) }
            } else {
                cells.append(contentsOf: line)
            }
            ends.append(UInt32(cells.count) | (wrapped ? Scrollback.wrappedBit : 0))
        }
    }

    static let wrappedBit: UInt32 = 1 << 31

    let columns: Int
    let limit: Int
    var chunks: [Chunk] = []
    /// The chunk released last, emptied and kept for the next one: a history that is full and rolling allocates nothing.
    private var spare: Chunk?
    /// Lines gone from the front of `chunks`: the chunks wholly gone stay in place, emptied, until `deadChunksLimit` of them are removed at once (removing
    /// the first element shifts the whole array: once every 128 lines it was 4 % of a scrolling flood with a full history).
    private var head = 0
    private static let deadChunksLimit = 64
    private(set) var count = 0
    /// How many lines have left the history so far (dropped when it was full, or cleared): with a line's index it makes a number that does not change while
    /// the history rolls (`PromptMark`).
    var evicted = 0

    init(columns: Int, limit: Int) {
        self.columns = columns
        self.limit = max(0, limit)
    }

    /// Cells held in memory: a line is kept without its trailing blank cells.
    var storedCells: Int { chunks.reduce(0) { $0 + $1.cells.count } }

    /// Lines held in memory, the ones past the limit that are not yet released included.
    var storedLines: Int { chunks.reduce(0) { $0 + $1.ends.count } }

    subscript(line: Int, column: Int) -> Cell {
        let (chunk, index) = locate(line)
        let start = index == 0 ? 0 : Int(chunks[chunk].ends[index - 1] & ~Self.wrappedBit)
        let end = Int(chunks[chunk].ends[index] & ~Self.wrappedBit)
        return column < end - start ? chunks[chunk].cell(at: start + column) : .empty
    }

    /// The cells of `line`, without its trailing blank cells (it is kept without them): one lookup for the line, not one a cell.
    func cells(line: Int) -> ArraySlice<Cell> {
        let (chunk, index) = locate(line)
        let start = index == 0 ? 0 : Int(chunks[chunk].ends[index - 1] & ~Self.wrappedBit)
        let end = Int(chunks[chunk].ends[index] & ~Self.wrappedBit)
        return (chunks[chunk].packed?.cells() ?? chunks[chunk].cells)[start ..< end]
    }

    func isWrapped(_ line: Int) -> Bool {
        let (chunk, index) = locate(line)
        return chunks[chunk].ends[index] & Self.wrappedBit != 0
    }

    func locate(_ line: Int) -> (chunk: Int, index: Int) {
        let absolute = head + line
        return (absolute / Self.chunkLines, absolute % Self.chunkLines)
    }

    /// Whether the chunk that holds `line` is stored in memory shared with a chunk of `other` (a copy not written to since): a copy must not pay for the lines.
    func sharesStorage(line: Int, with other: Scrollback) -> Bool {
        let (chunk, _) = locate(line)
        let address = chunks[chunk].ends.withUnsafeBufferPointer { $0.baseAddress }
        return other.chunks.contains { $0.ends.withUnsafeBufferPointer { $0.baseAddress } == address }
    }

    /// Adds a line at the newest end, dropping the oldest when full. `line` may stop short of `columns`: the cells after it are empty.
    mutating func push(_ line: ArraySlice<Cell>, wrapped isWrapped: Bool) {
        guard limit > 0 else {
            evicted += 1
            return
        }
        precondition(line.count <= columns, "a scrollback line is no wider than the screen was")
        if count == limit { dropOldest() }
        var newest = chunks.count - 1
        if newest < 0 || chunks[newest].ends.count == Self.chunkLines {
            var fresh = spare ?? Chunk()
            spare = nil
            fresh.ends.reserveCapacity(Self.chunkLines)
            chunks.append(fresh)
            newest = chunks.count - 1
        }
        // Only the cells up to the last one that is not blank: a line of text is mostly a few cells and then blanks, and the blanks are implied.
        line.withUnsafeBufferPointer { cells in
            let used = CellKernels.usedLength(cells)
            chunks[newest].append(UnsafeBufferPointer(rebasing: cells[0 ..< used]), wrapped: isWrapped)
        }
        count += 1
    }

    private mutating func dropOldest() {
        head += 1
        count -= 1
        evicted += 1
        guard head % Self.chunkLines == 0 else { return }
        // The chunk that just emptied is kept as the spare (its storage is used again) and an empty one takes its place.
        let dead = head / Self.chunkLines - 1
        var released = Chunk()
        swap(&released, &chunks[dead])
        if released.packed != nil {
            released.packed = nil
            released.cells = ContiguousArray()
        }
        released.cells.removeAll(keepingCapacity: true)
        released.ends.removeAll(keepingCapacity: true)
        spare = released
        if dead + 1 >= Self.deadChunksLimit {
            chunks.removeFirst(dead + 1)
            head -= (dead + 1) * Self.chunkLines
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
        var chunk = chunks.count - 1
        while chunk >= 0 {
            unpack(chunk)
            var index = chunks[chunk].cells.count - 1
            while index >= 0 {
                let cell = chunks[chunk].cells[index]
                chunks[chunk].cells[index] = cell.withStyle(map(cell.styleID))
                index -= 1
            }
            chunk -= 1
        }
    }
}
