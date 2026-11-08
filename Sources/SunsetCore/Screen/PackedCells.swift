internal import Synchronization

/// The cells of one history chunk in packed form. It is a class so that every copy of the history (a snapshot for the renderer) shares the packed bytes and the
/// decoded cells: a line is decoded once, on the first read, and the decoded cells stay until `releaseDecoded()` (idle again), so that scrolling through the
/// history does not decode a chunk for every line. Reading from several tasks at once is safe.
final class PackedCells: Sendable {
    let bytes: [UInt8]
    let count: Int
    private let codec: any HistoryCodec
    private let decoded = Mutex<ContiguousArray<Cell>?>(nil)

    init(bytes: [UInt8], count: Int, codec: any HistoryCodec) {
        self.bytes = bytes
        self.count = count
        self.codec = codec
    }

    func cell(at index: Int) -> Cell {
        decoded.withLock { cache in
            if cache == nil { cache = decode() }
            return cache.map { $0[index] } ?? .empty
        }
    }

    /// All the cells (decoded, and kept).
    func cells() -> ContiguousArray<Cell> {
        decoded.withLock { cache in
            if cache == nil { cache = decode() }
            return cache ?? ContiguousArray()
        }
    }

    func releaseDecoded() { decoded.withLock { $0 = nil } }

    /// Blank cells when the codec cannot unpack: a damaged line is a blank line, not a crash.
    private func decode() -> ContiguousArray<Cell> {
        var cells = ContiguousArray<Cell>(repeating: .empty, count: count)
        let done = cells.withUnsafeMutableBytes { unsafe codec.unpack(bytes, into: $0) }
        if !done { cells = ContiguousArray(repeating: .empty, count: count) }
        return cells
    }
}
