/// AAT lookup tables (Apple TrueType Reference Manual, "AAT Special Tables": formats 0, 2, 4, 6, 8 and 10), read for
/// one glyph at a time. Binary-search units are scanned in order, a 0xFFFF end marker matching no real glyph.
extension FontTableBytes {
    /// The value the lookup table at `table` gives `glyph`, or nil when it gives none.
    func lookup(_ table: Int, _ glyph: UInt16) throws(Malformed) -> Int? {
        let wanted = Int(glyph)
        switch try u16(table) {
            case 0:
                return try u16(table + 2 + 2 * wanted)
            case 2, 4, 6:
                return try searched(table, wanted)
            case 8:
                let first = try u16(table + 2)
                guard wanted >= first, wanted < first + (try u16(table + 4)) else { return nil }
                return try u16(table + 6 + 2 * (wanted - first))
            case 10:
                let size = try u16(table + 2)
                let first = try u16(table + 4)
                guard wanted >= first, wanted < first + (try u16(table + 6)) else { return nil }
                let at = table + 8 + size * (wanted - first)
                switch size {
                    case 1:
                        guard at >= 0, at < bytes.count else { throw Malformed() }
                        return Int(bytes[at])
                    case 2: return try u16(at)
                    case 4: return try u32(at)
                    default: throw Malformed()
                }
            default:
                throw Malformed()
        }
    }

    /// Formats 2 (segments of one value), 4 (segments of values) and 6 (single glyphs), after a BinSrchHeader.
    private func searched(_ table: Int, _ wanted: Int) throws(Malformed) -> Int? {
        let format = try u16(table)
        let unit = try u16(table + 2)
        let count = try u16(table + 4)
        guard unit >= (format == 6 ? 4 : 6) else { throw Malformed() }
        for index in 0 ..< count {
            let at = table + 12 + unit * index
            if format == 6 {
                if try u16(at) == wanted { return try u16(at + 2) }
                continue
            }
            let last = try u16(at)
            let first = try u16(at + 2)
            guard wanted >= first, wanted <= last else { continue }
            let value = try u16(at + 4)
            return format == 2 ? value : try u16(table + value + 2 * (wanted - first))
        }
        return nil
    }
}
