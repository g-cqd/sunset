/// A 94-character set a program can designate to G0 or G1 (`ESC ( F`, `ESC ) F`) and shift between (SI, SO).
enum Charset: UInt8, Sendable {
    case ascii
    /// DEC special graphics: line drawing, designated by `0`.
    case decSpecial
    /// The UK set: `#` is a pound sign, designated by `A`.
    case uk

    init(designator: UInt8) {
        switch designator {
            case 0x30: self = .decSpecial
            case 0x41: self = .uk
            default: self = .ascii
        }
    }

    /// The scalar a printable ASCII byte stands for in this set.
    func translate(_ byte: UInt8) -> UInt32 {
        switch self {
            case .ascii: return UInt32(byte)
            case .uk: return byte == 0x23 ? 0xA3 : UInt32(byte)
            case .decSpecial:
                guard byte >= 0x5F, byte <= 0x7E else { return UInt32(byte) }
                return Charset.specialGraphics[Int(byte) - 0x5F]
        }
    }

    // 0x5F ... 0x7E
    private static let specialGraphics: [UInt32] = [
        0xA0, 0x25C6, 0x2592, 0x2409, 0x240C, 0x240D, 0x240A, 0xB0, 0xB1, 0x2424, 0x240B, 0x2518, 0x2510, 0x250C,
        0x2514, 0x253C, 0x23BA, 0x23BB,
        0x2500, 0x23BC, 0x23BD, 0x251C, 0x2524, 0x2534, 0x252C, 0x2502, 0x2264, 0x2265, 0x3C0, 0x2260, 0xA3, 0xB7
    ]
}
