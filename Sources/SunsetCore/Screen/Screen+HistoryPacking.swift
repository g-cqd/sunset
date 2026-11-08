extension Screen {
    /// Packs the old lines of the history (`Scrollback.pack`): at most `limit` chunks, all but the newest `keepingRecent` full ones. Returns how many were packed.
    @discardableResult
    public mutating func packHistory(using codec: any HistoryCodec, keepingRecent: Int, limit: Int) -> Int {
        scrollback.pack(using: codec, keepingRecent: keepingRecent, limit: limit)
    }

    /// Drops the cells that reading packed lines decoded.
    public func releaseDecodedHistory() { scrollback.releaseDecoded() }

    public var historyFootprint: HistoryFootprint {
        HistoryFootprint(
            packedChunks: scrollback.packedChunks,
            packedBytes: scrollback.packedBytes,
            hotCells: scrollback.storedCells
        )
    }

    /// Takes the history of `other` (a later copy of this screen whose history was packed) in place of this copy's own, which then lets go of the cells it
    /// shares with nothing else. Only when both hold as many lines and have dropped as many, in the same width: the same history, not one that has moved on
    /// (a copy that is behind is replaced by the next frame anyway). Returns whether it did.
    @discardableResult
    public mutating func adoptHistory(from other: Screen) -> Bool {
        guard scrollback.columns == other.scrollback.columns, scrollback.count == other.scrollback.count,
            scrollback.evicted == other.scrollback.evicted
        else { return false }
        scrollback = other.scrollback
        return true
    }
}
