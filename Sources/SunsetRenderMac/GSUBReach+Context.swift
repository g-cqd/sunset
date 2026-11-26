/// Contextual and chained contextual substitution (GSUB types 5 and 6, formats 1 to 3): a rule fires where each of its
/// positions (backtrack, input, lookahead) can hold a glyph of the set and one of its lookup records can change the
/// glyph at its input position. Records run in order on the run as it stands; while none changes a glyph, each sees
/// the glyphs the rule matched, so a rule none of whose records can change those changes nothing.
extension GSUBReach {
    /// A rule: the glyphs of the set each position can hold, where the input sequence starts, and its lookup records.
    struct Rule {
        var positions: [Set<UInt16>]
        var inputStart: Int
        var inputCount: Int
        var records: [(sequenceIndex: Int, lookup: Int)]
    }

    func contextFirings(chained: Bool, _ base: Int, _ glyphs: Set<UInt16>) throws(Malformed) -> [Firing] {
        var found: [Firing] = []
        for rule in try rules(chained: chained, base, glyphs) where !rule.positions.contains(where: \.isEmpty) {
            for record in rule.records {
                guard record.sequenceIndex < rule.inputCount else { throw Malformed() }
                let position = rule.inputStart + record.sequenceIndex
                let changed = try changeable(record.lookup, rule.positions[position])
                guard !changed.isEmpty else { continue }
                var alternatives = rule.positions
                alternatives[position] = changed
                found.append(Firing(alternatives: alternatives))
            }
        }
        return found
    }

    /// The glyphs of `glyphs` lookup `index` could change where it is applied to one of them; a nested contextual
    /// lookup, any of them.
    private func changeable(_ index: Int, _ glyphs: Set<UInt16>) throws(Malformed) -> Set<UInt16> {
        var changed = Set<UInt16>()
        for (type, base) in try subtables(index) {
            switch type {
                case 1: changed.formUnion(try changedBySingle(base, glyphs))
                case 2, 3, 4: changed.formUnion(try table.covered(base + (try table.u16(base + 2)), glyphs))
                case 5, 6, 8: return glyphs
                default: throw Malformed()
            }
        }
        return changed
    }

    private func rules(chained: Bool, _ base: Int, _ glyphs: Set<UInt16>) throws(Malformed) -> [Rule] {
        switch try table.u16(base) {
            case 1: return try glyphRules(chained: chained, base, glyphs)
            case 2: return try classRules(chained: chained, base, glyphs)
            case 3: return [try coverageRule(chained: chained, base, glyphs)]
            default: throw Malformed()
        }
    }

    /// Format 1: rule sets by the first glyph's Coverage Index; the other positions are glyph IDs.
    private func glyphRules(chained: Bool, _ base: Int, _ glyphs: Set<UInt16>) throws(Malformed) -> [Rule] {
        let coverage = base + (try table.u16(base + 2))
        let setCount = try table.u16(base + 4)
        var found: [Rule] = []
        for first in glyphs.sorted() {
            guard let index = try table.coverageIndex(coverage, first), index < setCount,
                let set = try table.offset16(base + 6 + 2 * index, from: base)
            else { continue }
            for rule in try ruleOffsets(set) {
                found.append(
                    try parseRule(chained: chained, rule) { part, value throws(Malformed) in
                        part == .first ? [first] : glyphs.intersection([UInt16(value)])
                    }
                )
            }
        }
        return found
    }

    /// Format 2: rule sets by the first glyph's class; the other positions are classes of their part's ClassDef.
    private func classRules(chained: Bool, _ base: Int, _ glyphs: Set<UInt16>) throws(Malformed) -> [Rule] {
        let coverage = base + (try table.u16(base + 2))
        let definitions: [Part: Int?] =
            chained
            ? [
                .backtrack: try table.offset16(base + 4, from: base), .input: try table.offset16(base + 6, from: base),
                .lookahead: try table.offset16(base + 8, from: base)
            ]
            : [.input: try table.offset16(base + 4, from: base)]
        var classes: [Part: [Int: Set<UInt16>]] = [:]
        for (part, definition) in definitions {
            for glyph in glyphs {
                classes[part, default: [:]][try table.glyphClass(definition, glyph), default: []].insert(glyph)
            }
        }
        let setCount = try table.u16(base + (chained ? 10 : 6))
        let sets = base + (chained ? 12 : 8)
        var found: [Rule] = []
        let covered = try table.covered(coverage, glyphs)
        for (inputClass, members) in classes[.input] ?? [:] where inputClass < setCount {
            let first = members.intersection(covered)
            guard !first.isEmpty, let set = try table.offset16(sets + 2 * inputClass, from: base) else { continue }
            for rule in try ruleOffsets(set) {
                found.append(
                    try parseRule(chained: chained, rule) { part, value throws(Malformed) in
                        part == .first ? first : classes[part]?[value] ?? []
                    }
                )
            }
        }
        return found
    }

    /// Format 3: one rule, each position a Coverage table.
    private func coverageRule(chained: Bool, _ base: Int, _ glyphs: Set<UInt16>) throws(Malformed) -> Rule {
        func coverages(_ at: Int) throws(Malformed) -> (positions: [Set<UInt16>], next: Int) {
            let count = try table.u16(at)
            var positions: [Set<UInt16>] = []
            for field in try table.u16s(at + 2, count: count) {
                positions.append(try table.covered(base + field, glyphs))
            }
            return (positions, at + 2 + 2 * count)
        }
        if chained {
            let backtrack = try coverages(base + 2)
            let input = try coverages(backtrack.next)
            let lookahead = try coverages(input.next)
            return Rule(
                positions: backtrack.positions + input.positions + lookahead.positions,
                inputStart: backtrack.positions.count,
                inputCount: input.positions.count,
                records: try records(lookahead.next)
            )
        }
        let count = try table.u16(base + 2)
        var positions: [Set<UInt16>] = []
        for field in try table.u16s(base + 6, count: count) {
            positions.append(try table.covered(base + field, glyphs))
        }
        let recordCount = try table.u16(base + 4)
        return Rule(
            positions: positions,
            inputStart: 0,
            inputCount: count,
            records: try recordList(base + 6 + 2 * count, count: recordCount)
        )
    }

    /// Which part of a rule a value names a glyph (format 1) or class (format 2) for; `first` is the input's first.
    enum Part: Hashable {
        case backtrack, first, input, lookahead
    }

    private func ruleOffsets(_ set: Int) throws(Malformed) -> [Int] {
        try table.u16s(set + 2, count: try table.u16(set)).map { set + $0 }
    }

    /// A SequenceRule or ChainedSequenceRule (and their class forms, laid out alike) at `rule`.
    private func parseRule(
        chained: Bool,
        _ rule: Int,
        position: (Part, Int) throws(Malformed) -> Set<UInt16>
    ) throws(Malformed) -> Rule {
        var at = rule
        var positions: [Set<UInt16>] = []
        if chained {
            let backtrack = try table.u16(at)
            for value in try table.u16s(at + 2, count: backtrack) { positions.append(try position(.backtrack, value)) }
            at += 2 + 2 * backtrack
        }
        let inputStart = positions.count
        let inputCount = try table.u16(at)
        guard inputCount >= 1 else { throw Malformed() }
        positions.append(try position(.first, 0))
        if chained {
            for value in try table.u16s(at + 2, count: inputCount - 1) { positions.append(try position(.input, value)) }
            at += 2 + 2 * (inputCount - 1)
            let lookahead = try table.u16(at)
            for value in try table.u16s(at + 2, count: lookahead) { positions.append(try position(.lookahead, value)) }
            return Rule(
                positions: positions,
                inputStart: inputStart,
                inputCount: inputCount,
                records: try records(at + 2 + 2 * lookahead)
            )
        }
        let recordCount = try table.u16(at + 2)
        for value in try table.u16s(at + 4, count: inputCount - 1) { positions.append(try position(.input, value)) }
        return Rule(
            positions: positions,
            inputStart: 0,
            inputCount: inputCount,
            records: try recordList(at + 4 + 2 * (inputCount - 1), count: recordCount)
        )
    }

    /// seqLookupCount, then the records.
    private func records(_ at: Int) throws(Malformed) -> [(sequenceIndex: Int, lookup: Int)] {
        try recordList(at + 2, count: try table.u16(at))
    }

    private func recordList(_ at: Int, count: Int) throws(Malformed) -> [(sequenceIndex: Int, lookup: Int)] {
        let values = try table.u16s(at, count: 2 * count)
        return (0 ..< count).map { (values[2 * $0], values[2 * $0 + 1]) }
    }
}
