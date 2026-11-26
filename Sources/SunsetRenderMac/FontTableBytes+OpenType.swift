/// OpenType's Coverage and ClassDef tables (OpenType 1.9.1, "OpenType Layout Common Table Formats"), asked only about
/// the glyphs a question is about.
extension FontTableBytes {
    /// The glyph's Coverage Index in the Coverage table at `table`, or nil when it is not covered.
    func coverageIndex(_ table: Int, _ glyph: UInt16) throws(Malformed) -> Int? {
        let wanted = Int(glyph)
        switch try u16(table) {
            case 1:
                // Format 1: glyphCount, then the glyph IDs in increasing order.
                let count = try u16(table + 2)
                var low = 0
                var high = count - 1
                while low <= high {
                    let middle = (low + high) / 2
                    let found = try u16(table + 4 + 2 * middle)
                    if found == wanted { return middle }
                    if found < wanted { low = middle + 1 } else { high = middle - 1 }
                }
                return nil
            case 2:
                // Format 2: rangeCount, then (startGlyphID, endGlyphID, startCoverageIndex) records.
                let count = try u16(table + 2)
                for range in 0 ..< count {
                    let record = table + 4 + 6 * range
                    let start = try u16(record)
                    let end = try u16(record + 2)
                    if wanted >= start, wanted <= end { return try u16(record + 4) + wanted - start }
                }
                return nil
            default:
                throw Malformed()
        }
    }

    /// The glyphs of `glyphs` the Coverage table at `table` covers.
    /// The glyphs of `glyphs` the Coverage table at `table` names, in glyph order, each with its Coverage index.
    func coverageIndices(_ table: Int, _ glyphs: Set<UInt16>) throws(Malformed) -> [(glyph: UInt16, index: Int)] {
        var found: [(glyph: UInt16, index: Int)] = []
        for glyph in glyphs.sorted() {
            if let index = try coverageIndex(table, glyph) { found.append((glyph, index)) }
        }
        return found
    }

    func covered(_ table: Int, _ glyphs: Set<UInt16>) throws(Malformed) -> Set<UInt16> {
        var found = Set<UInt16>()
        for glyph in glyphs where try coverageIndex(table, glyph) != nil { found.insert(glyph) }
        return found
    }

    /// The glyph's class in the ClassDef table at `table` (nil table: every glyph is class 0); a glyph it does not name
    /// is class 0.
    func glyphClass(_ table: Int?, _ glyph: UInt16) throws(Malformed) -> Int {
        guard let table else { return 0 }
        let wanted = Int(glyph)
        switch try u16(table) {
            case 1:
                // Format 1: startGlyphID, glyphCount, then one class per glyph from the start.
                let start = try u16(table + 2)
                let count = try u16(table + 4)
                guard wanted >= start, wanted < start + count else { return 0 }
                return try u16(table + 6 + 2 * (wanted - start))
            case 2:
                // Format 2: classRangeCount, then (startGlyphID, endGlyphID, class) records.
                let count = try u16(table + 2)
                for range in 0 ..< count {
                    let record = table + 4 + 6 * range
                    if wanted >= (try u16(record)), wanted <= (try u16(record + 2)) { return try u16(record + 4) }
                }
                return 0
            default:
                throw Malformed()
        }
    }
}
