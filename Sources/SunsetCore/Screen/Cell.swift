/// A colour as the terminal was told it: the default, a palette index, or true colour. Packed in 32 bits (tag in the top byte).
public struct Color: Sendable, Hashable {
    let raw: UInt32

    public static let `default` = Color(raw: 0)
    public static func indexed(_ index: UInt8) -> Color { Color(raw: 1 << 24 | UInt32(index)) }
    public static func rgb(_ red: UInt8, _ green: UInt8, _ blue: UInt8) -> Color {
        Color(raw: 2 << 24 | UInt32(red) << 16 | UInt32(green) << 8 | UInt32(blue))
    }

    public var isDefault: Bool { raw == 0 }
    /// The colour as stored (tag in the top byte, then the palette index or the three bytes): for tools that print or compare colours.
    public var packed: UInt32 { raw }
}

public enum UnderlineStyle: UInt8, Sendable {
    case none, single, double, curly, dotted, dashed
}

public struct Attributes: OptionSet, Sendable, Hashable {
    public let rawValue: UInt8
    public init(rawValue: UInt8) { self.rawValue = rawValue }

    public static let bold = Attributes(rawValue: 1 << 0)
    public static let faint = Attributes(rawValue: 1 << 1)
    public static let italic = Attributes(rawValue: 1 << 2)
    public static let blink = Attributes(rawValue: 1 << 3)
    public static let inverse = Attributes(rawValue: 1 << 4)
    public static let invisible = Attributes(rawValue: 1 << 5)
    public static let strikethrough = Attributes(rawValue: 1 << 6)
    public static let overline = Attributes(rawValue: 1 << 7)
}

/// What a run of cells looks like (everything but the character). Cells hold a 16-bit id into the screen's style table, not this value.
public struct CellStyle: Sendable, Hashable {
    public var foreground = Color.default
    public var background = Color.default
    public var underlineColor = Color.default
    public var attributes: Attributes = []
    public var underline = UnderlineStyle.none

    public init() {}
}

public enum CellWidth: UInt8, Sendable {
    case narrow = 0
    /// The left half of a double-width character; the next cell is its `spacerTail`.
    case wide = 1
    case spacerTail = 2
    /// The blank at the end of a row where a double-width character did not fit and went to the next row; a reflow drops it.
    case spacerHead = 3
}

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
