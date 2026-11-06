/// One screen cell in 8 bytes (ADR-0012): scalar (21 bits; 0 is an empty cell), width class (2 bits), a cluster flag, style id (16 bits).
public struct Cell: Sendable, Equatable {
    var raw: UInt64

    static let empty = Cell(raw: 0)

    init(raw: UInt64) { self.raw = raw }

    init(scalar: UInt32, width: CellWidth, style: UInt16) {
        raw = UInt64(scalar) | UInt64(width.rawValue) << 21 | UInt64(style) << 24
    }

    static let clusterFlag: UInt64 = 1 << 23

    /// A cell whose text is a grapheme cluster of several scalars: `id` indexes the screen's cluster table (ids start at 1).
    init(cluster id: UInt32, width: CellWidth, style: UInt16) {
        raw = UInt64(id) | UInt64(width.rawValue) << 21 | Cell.clusterFlag | UInt64(style) << 24
    }

    /// The scalar, or for a cluster cell (`isCluster`) the id of its cluster.
    public var scalar: UInt32 { UInt32(truncatingIfNeeded: raw & 0x1F_FFFF) }
    public var isCluster: Bool { raw & Cell.clusterFlag != 0 }
    public var width: CellWidth { CellWidth(rawValue: UInt8(truncatingIfNeeded: raw >> 21) & 3) ?? .narrow }
    public var styleID: UInt16 { UInt16(truncatingIfNeeded: raw >> 24) }

    func withStyle(_ style: UInt16) -> Cell { Cell(raw: raw & ~(0xFFFF << 24) | UInt64(style) << 24) }
}
