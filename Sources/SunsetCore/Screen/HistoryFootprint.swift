/// What the history holds in memory.
public struct HistoryFootprint: Sendable, Equatable {
    /// Chunks of 128 lines held in packed form.
    public let packedChunks: Int
    /// Bytes the packed chunks take.
    public let packedBytes: Int
    /// Cells held as they are (8 bytes each): the chunks not packed.
    public let hotCells: Int
}
