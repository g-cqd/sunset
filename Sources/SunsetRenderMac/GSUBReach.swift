/// The ways an OpenType `GSUB` table could change a run of glyphs drawn from a set (OpenType 1.9.1, "GSUB — Glyph
/// Substitution Table" and "OpenType Layout Common Table Formats"). Over-approximated throughout: the lookups of every
/// applied feature in any script and language system, and of every alternate a feature variation may put in its
/// place; lookup flags (glyphs skipped) are left out, as skipping only lets fewer rules match glyphs of the set.
struct GSUBReach: SubstitutionTable {
    typealias Firing = SubstitutionReach.Firing
    typealias Malformed = FontTableBytes.Malformed

    let table: FontTableBytes
    let lookupList: Int
    /// The lookups of applied features, in LookupList order.
    let lookups: [Int]

    init(_ bytes: [UInt8], isApplied: (String) -> Bool) throws(Malformed) {
        let table = FontTableBytes(bytes)
        guard try table.u16(0) == 1 else { throw Malformed() }
        let minor = try table.u16(2)
        let scriptList = try table.u16(4)
        let featureList = try table.u16(6)
        self.table = table
        lookupList = try table.u16(8)
        let features = try Self.features(table, scriptList)
        var lookups = Set<Int>()
        var featureTables: [Int: [Int]] = [:]
        let featureCount = try table.u16(featureList)
        for index in features {
            guard index < featureCount else { throw Malformed() }
            let record = featureList + 2 + 6 * index
            guard isApplied(try table.tag(record)) else { continue }
            featureTables[index, default: []].append(featureList + (try table.u16(record + 4)))
        }
        if minor >= 1, case let variations = try table.u32(10), variations != 0 {
            for (index, alternate) in try Self.alternates(table, variations) where featureTables[index] != nil {
                featureTables[index, default: []].append(alternate)
            }
        }
        for feature in featureTables.values.joined() {
            lookups.formUnion(try table.u16s(feature + 4, count: try table.u16(feature + 2)))
        }
        self.lookups = lookups.sorted()
    }

    /// The feature indices of every language system of every script in the ScriptList at `scriptList`, required
    /// features included: which script and language a run is shaped as is not known here.
    private static func features(_ table: FontTableBytes, _ scriptList: Int) throws(Malformed) -> Set<Int> {
        var features = Set<Int>()
        for script in 0 ..< (try table.u16(scriptList)) {
            let base = scriptList + (try table.u16(scriptList + 2 + 6 * script + 4))
            var systems: [Int] = []
            if let defaultSystem = try table.offset16(base, from: base) { systems.append(defaultSystem) }
            for system in 0 ..< (try table.u16(base + 2)) {
                systems.append(base + (try table.u16(base + 4 + 6 * system + 4)))
            }
            for system in systems {
                let required = try table.u16(system + 2)
                if required != 0xFFFF { features.insert(required) }
                features.formUnion(try table.u16s(system + 6, count: try table.u16(system + 4)))
            }
        }
        return features
    }

    /// Every alternate feature table of the FeatureVariations table at `base`, by the feature index it replaces: any
    /// may be chosen, by axis values the shaper is given.
    private static func alternates(_ table: FontTableBytes, _ base: Int) throws(Malformed) -> [(Int, Int)] {
        var found: [(Int, Int)] = []
        for record in 0 ..< (try table.u32(base + 4)) {
            let substitution = try table.u32(base + 8 + 8 * record + 4)
            guard substitution != 0 else { continue }
            let start = base + substitution
            for entry in 0 ..< (try table.u16(start + 4)) {
                let field = start + 6 + 6 * entry
                found.append((try table.u16(field), start + (try table.u32(field + 2))))
            }
        }
        return found
    }

    /// The subtables of lookup `index` with their type, through Extension subtables (type 7).
    func subtables(_ index: Int) throws(Malformed) -> [(type: Int, at: Int)] {
        guard index < (try table.u16(lookupList)) else { throw Malformed() }
        let lookup = lookupList + (try table.u16(lookupList + 2 + 2 * index))
        let type = try table.u16(lookup)
        var found: [(type: Int, at: Int)] = []
        for subtable in 0 ..< (try table.u16(lookup + 4)) {
            let base = lookup + (try table.u16(lookup + 6 + 2 * subtable))
            if type == 7 {
                guard try table.u16(base) == 1 else { throw Malformed() }
                found.append((try table.u16(base + 2), base + (try table.u32(base + 4))))
            } else {
                found.append((type, base))
            }
        }
        return found
    }

    func firings(within glyphs: Set<UInt16>) throws(Malformed) -> [Firing] {
        var found: [Firing] = []
        for lookup in lookups {
            for (type, base) in try subtables(lookup) {
                found += try firings(type: type, base, glyphs)
                guard found.count <= SubstitutionReach.budget else { throw Malformed() }
            }
        }
        return found
    }

    private func firings(type: Int, _ base: Int, _ glyphs: Set<UInt16>) throws(Malformed) -> [Firing] {
        switch type {
            case 1:
                return try changedBySingle(base, glyphs).map { Firing(alternatives: [[$0]]) }
            case 2, 3:
                // Multiple and alternate substitution: a covered glyph is replaced.
                let coverage = base + (try table.u16(base + 2))
                return try table.covered(coverage, glyphs).map { Firing(alternatives: [[$0]]) }
            case 4:
                return try ligatures(base, glyphs)
            case 5, 6:
                return try contextFirings(chained: type == 6, base, glyphs)
            case 8:
                return try reverseChain(base, glyphs)
            default:
                throw Malformed()
        }
    }

    /// The glyphs of `glyphs` a Single Substitution subtable replaces by another glyph.
    func changedBySingle(_ base: Int, _ glyphs: Set<UInt16>) throws(Malformed) -> [UInt16] {
        let format = try table.u16(base)
        var changed: [UInt16] = []
        for (glyph, index) in try table.coverageIndices(base + (try table.u16(base + 2)), glyphs) {
            let substitute: Int
            switch format {
                case 1: substitute = (Int(glyph) + Int(Int16(truncatingIfNeeded: try table.u16(base + 4)))) & 0xFFFF
                case 2: substitute = try table.element(base + 4, index)
                default: throw Malformed()
            }
            if substitute != Int(glyph) { changed.append(glyph) }
        }
        return changed
    }

    /// The glyphs of `glyphs` in the Coverage of the subtable at `base`, which must be of format 1, with their index.
    private func formatOneCoverage(_ base: Int, _ glyphs: Set<UInt16>) throws(Malformed) -> [(
        glyph: UInt16, index: Int
    )] {
        guard try table.u16(base) == 1 else { throw Malformed() }
        return try table.coverageIndices(base + (try table.u16(base + 2)), glyphs)
    }

    /// Ligatures whose glyphs are all in `glyphs`: each stops forming without any one of them.
    private func ligatures(_ base: Int, _ glyphs: Set<UInt16>) throws(Malformed) -> [Firing] {
        var found: [Firing] = []
        for (glyph, index) in try formatOneCoverage(base, glyphs) {
            let set = base + (try table.element(base + 4, index))
            for ligature in 0 ..< (try table.u16(set)) {
                let start = set + (try table.u16(set + 2 + 2 * ligature))
                let count = try table.u16(start + 2)
                guard count >= 1 else { throw Malformed() }
                let components = try table.u16s(start + 4, count: count - 1).map { UInt16($0) }
                guard components.allSatisfy(glyphs.contains) else { continue }
                found.append(Firing(alternatives: [[glyph]] + components.map { [$0] }))
            }
        }
        return found
    }

    /// Reverse Chaining Contextual Single Substitution: the glyph changed, with its backtrack and lookahead positions.
    private func reverseChain(_ base: Int, _ glyphs: Set<UInt16>) throws(Malformed) -> [Firing] {
        let covered = try formatOneCoverage(base, glyphs)
        let backtrack = try table.u16(base + 4)
        let lookahead = try table.u16(base + 6 + 2 * backtrack)
        let substitutes = base + 8 + 2 * (backtrack + lookahead)
        var current = Set<UInt16>()
        for (glyph, index) in covered where try table.element(substitutes, index) != Int(glyph) {
            current.insert(glyph)
        }
        var positions = [current]
        for field in try table.u16s(base + 6, count: backtrack) + table.u16s(base + 8 + 2 * backtrack, count: lookahead)
        {
            positions.append(try table.covered(base + field, glyphs))
        }
        return positions.contains(where: \.isEmpty) ? [] : [Firing(alternatives: positions)]
    }
}
