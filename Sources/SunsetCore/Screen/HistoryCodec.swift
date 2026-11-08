/// Packs and unpacks the cells of old history lines (`Scrollback.pack`). The core knows no compression library (it is platform-free): the host gives it one.
public protocol HistoryCodec: Sendable {
    /// The packed form of `bytes` (a whole number of 8-byte cells), or nil when it would not be smaller.
    func pack(_ bytes: UnsafeRawBufferPointer) -> [UInt8]?

    /// Unpacks `packed` into `output`, which is exactly the size that was packed. False when it cannot (the lines then read as blank).
    func unpack(_ packed: [UInt8], into output: UnsafeMutableRawBufferPointer) -> Bool
}
