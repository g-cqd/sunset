/// Small `GSUB` tables, laid out as OpenType 1.9.1 has them, for the substitution reach tests: one script (DFLT) whose
/// default language system has every feature, the lookups as given, and optionally a FeatureVariations table whose one
/// record puts alternates in place of features.
struct GSUBTableBuilder {
    var features: [(tag: String, lookups: [Int])]
    var lookups: [(type: Int, subtables: [[UInt8]])]
    var alternates: [(feature: Int, lookups: [Int])] = []

    static func u16(_ value: Int) -> [UInt8] {
        [UInt8(value >> 8 & 0xFF), UInt8(value & 0xFF)]
    }

    static func u32(_ value: Int) -> [UInt8] {
        u16(value >> 16 & 0xFFFF) + u16(value & 0xFFFF)
    }

    /// A Coverage table, format 1.
    static func coverage(_ glyphs: [Int]) -> [UInt8] {
        u16(1) + u16(glyphs.count) + glyphs.sorted().flatMap(u16)
    }

    /// Single substitution, format 2: each glyph to its substitute.
    static func single(_ pairs: [(Int, Int)]) -> [UInt8] {
        let sorted = pairs.sorted { $0.0 < $1.0 }
        let head = 6 + 2 * sorted.count
        return u16(2) + u16(head) + u16(sorted.count) + sorted.flatMap { u16($0.1) } + coverage(sorted.map(\.0))
    }

    /// Ligature substitution, format 1: one ligature of `components` into `ligature`.
    static func ligature(_ components: [Int], into ligature: Int) -> [UInt8] {
        let set = u16(1) + u16(4) + u16(ligature) + u16(components.count) + components.dropFirst().flatMap(u16)
        return u16(1) + u16(8 + set.count) + u16(1) + u16(8) + set + coverage([components[0]])
    }

    /// Chained contextual substitution, format 3: each position one Coverage; `records` (sequence index, lookup).
    static func chained(backtrack: [[Int]], input: [[Int]], lookahead: [[Int]], records: [(Int, Int)]) -> [UInt8] {
        let head = 2 + 6 + 2 * (backtrack.count + input.count + lookahead.count) + 2 + 4 * records.count
        var tables: [UInt8] = []
        var offsets: [[Int]] = []
        for part in [backtrack, input, lookahead] {
            offsets.append(
                part.map { glyphs in
                    defer { tables += coverage(glyphs) }
                    return head + tables.count
                }
            )
        }
        var bytes = u16(3)
        for part in offsets { bytes += u16(part.count) + part.flatMap(u16) }
        bytes += u16(records.count) + records.flatMap { u16($0.0) + u16($0.1) }
        return bytes + tables
    }

    func bytes() -> [UInt8] {
        typealias B = Self
        let header = alternates.isEmpty ? 10 : 14
        let indices = Array(features.indices)
        let langSys = B.u16(0) + B.u16(0xFFFF) + B.u16(indices.count) + indices.flatMap(B.u16)
        let scriptList = B.u16(1) + Array("DFLT".utf8) + B.u16(8) + B.u16(4) + B.u16(0) + langSys
        var featureTables: [UInt8] = []
        var featureRecords: [UInt8] = []
        for feature in features {
            featureRecords += Array(feature.tag.utf8) + B.u16(2 + 6 * features.count + featureTables.count)
            featureTables += B.u16(0) + B.u16(feature.lookups.count) + feature.lookups.flatMap(B.u16)
        }
        let featureList = B.u16(features.count) + featureRecords + featureTables
        var lookupTables: [UInt8] = []
        var lookupOffsets: [UInt8] = []
        for lookup in lookups {
            lookupOffsets += B.u16(2 + 2 * lookups.count + lookupTables.count)
            var body: [UInt8] = []
            var offsets: [UInt8] = []
            for subtable in lookup.subtables {
                offsets += B.u16(6 + 2 * lookup.subtables.count + body.count)
                body += subtable
            }
            lookupTables += B.u16(lookup.type) + B.u16(0) + B.u16(lookup.subtables.count) + offsets + body
        }
        let lookupList = B.u16(lookups.count) + lookupOffsets + lookupTables
        let scriptAt = header
        let featureAt = scriptAt + scriptList.count
        let lookupAt = featureAt + featureList.count
        let variationsAt = lookupAt + lookupList.count
        var bytes = B.u16(1) + B.u16(alternates.isEmpty ? 0 : 1) + B.u16(scriptAt) + B.u16(featureAt) + B.u16(lookupAt)
        if !alternates.isEmpty { bytes += B.u32(variationsAt) }
        bytes += scriptList + featureList + lookupList
        guard !alternates.isEmpty else { return bytes }
        // FeatureVariations: one record, no condition set, its substitution table right after.
        var substitution = B.u16(1) + B.u16(0) + B.u16(alternates.count)
        var tables: [UInt8] = []
        for alternate in alternates {
            substitution += B.u16(alternate.feature) + B.u32(6 + 6 * alternates.count + tables.count)
            tables += B.u16(0) + B.u16(alternate.lookups.count) + alternate.lookups.flatMap(B.u16)
        }
        return bytes + B.u16(1) + B.u16(0) + B.u32(1) + B.u32(0) + B.u32(16) + substitution + tables
    }
}
