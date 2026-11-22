/// The seam that reads compressed images (`o=z`, a zlib stream: ADR-0117, roadmap 0010 D): the host gives one (Compression
/// on macOS, `ZlibInflater`); without one, compressed images are refused.
public protocol Inflater: Sendable {
    /// `data` inflated, or nil when it is not a whole zlib stream or inflates to more than `limit` bytes (never more than
    /// `limit` is written: a small stream can stand for a huge one).
    func inflate(_ data: [UInt8], limit: Int) -> [UInt8]?
}
