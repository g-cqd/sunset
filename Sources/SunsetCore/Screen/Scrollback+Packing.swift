extension Scrollback {
    /// Chunks held in packed form.
    var packedChunks: Int { chunks.reduce(0) { $0 + ($1.packed == nil ? 0 : 1) } }

    /// Bytes the packed chunks take.
    var packedBytes: Int { chunks.reduce(0) { $0 + ($1.packed?.bytes.count ?? 0) } }

    /// Packs the old full chunks, all but the newest `keepingRecent` full ones (the chunk still being filled is never packed, so a line is never added to a packed
    /// chunk), at most `limit` of them (the caller packs in small steps so that the terminal is never locked for long). A chunk the codec cannot make smaller stays as it is. Returns how many chunks were packed. Reading a packed line decodes its chunk on demand.
    @discardableResult
    mutating func pack(using codec: any HistoryCodec, keepingRecent: Int, limit: Int = .max) -> Int {
        let full = chunks.indices.filter { chunks[$0].ends.count == Self.chunkLines }
        var packed = 0
        for index in full.dropLast(max(0, keepingRecent)) where chunks[index].packed == nil {
            if packed >= limit { break }
            let count = chunks[index].cells.count
            guard count > 0, let bytes = chunks[index].cells.withUnsafeBytes({ codec.pack($0) }) else { continue }
            chunks[index].packed = PackedCells(bytes: bytes, count: count, codec: codec)
            chunks[index].cells = ContiguousArray()
            packed += 1
        }
        return packed
    }

    /// Drops the cells that reading packed chunks decoded (they are decoded again on the next read): the history is as small as it can be again.
    func releaseDecoded() {
        for chunk in chunks { chunk.packed?.releaseDecoded() }
    }

    /// Takes a chunk out of its packed form for good (before its cells are rewritten).
    mutating func unpack(_ index: Int) {
        guard let packed = chunks[index].packed else { return }
        chunks[index].cells = packed.cells()
        chunks[index].packed = nil
    }
}
