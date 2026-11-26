/// The ways an AAT `morx` table (version 2 or 3; Apple TrueType Reference Manual, "The 'morx' table" and "AAT Special
/// Tables") could change a run of glyphs drawn from a set. Over-approximated: a subtable counts when its feature flags
/// meet the chain's defaults or what any feature setting could enable; a state table's states are those reachable
/// through classes of the set's glyphs and the fixed end-of-text and end-of-line classes, in any order; and any entry
/// with an action counts as changing glyphs.
struct MorxReach: SubstitutionTable {
    typealias Firing = SubstitutionReach.Firing
    typealias Malformed = FontTableBytes.Malformed

    /// The most states a walk visits: a run of ASCII goes through few, and the work grows with their square.
    static let stateLimit = 512

    /// A subtable that counts: its type and where its body (after the 12-byte header) starts.
    let subtables: [(type: Int, body: Int)]
    let table: FontTableBytes

    init(_ bytes: [UInt8]) throws(Malformed) {
        let table = FontTableBytes(bytes)
        guard [2, 3].contains(try table.u16(0)) else { throw Malformed() }
        var chain = 8
        var found: [(type: Int, body: Int)] = []
        for _ in 0 ..< (try table.u32(4)) {
            var flags = try table.u32(chain)
            let length = try table.u32(chain + 4)
            let features = try table.u32(chain + 8)
            for feature in 0 ..< features { flags |= try table.u32(chain + 16 + 12 * feature + 4) }
            var subtable = chain + 16 + 12 * features
            for _ in 0 ..< (try table.u32(chain + 12)) {
                let size = try table.u32(subtable)
                let coverage = try table.u32(subtable + 4)
                let horizontal = coverage & 0x8000_0000 == 0 || coverage & 0x2000_0000 != 0
                if horizontal, try table.u32(subtable + 8) & flags != 0 {
                    found.append((coverage & 0xFF, subtable + 12))
                }
                guard size >= 12 else { throw Malformed() }
                subtable += size
            }
            guard length >= 16 else { throw Malformed() }
            chain += length
        }
        self.table = table
        subtables = found
    }

    func firings(within glyphs: Set<UInt16>) throws(Malformed) -> [Firing] {
        var found: [Firing] = []
        for (type, body) in subtables {
            switch type {
                case 4:
                    for glyph in glyphs.sorted() {
                        if let value = try table.lookup(body, glyph), value != Int(glyph) {
                            found.append(Firing(alternatives: [[glyph]]))
                        }
                    }
                case 0, 1, 2, 5:
                    found += try stateFirings(type: type, body, glyphs)
                default:
                    throw Malformed()
            }
        }
        return found
    }

    /// Size of an entry, and whether it acts, by subtable type: rearrangement (verb), contextual (mark or current
    /// substitution), ligature (perform action), insertion (glyphs to insert).
    private func acts(type: Int, entry: Int) throws(Malformed) -> Bool {
        let flags = try table.u16(entry + 2)
        switch type {
            case 0: return flags & 0x000F != 0
            case 1:
                let mark = try table.u16(entry + 4)
                let current = try table.u16(entry + 6)
                return mark != 0xFFFF || current != 0xFFFF
            case 2: return flags & 0x2000 != 0
            default: return flags & 0x03FF != 0
        }
    }

    /// Breadth-first through the state table from both start states. Each acting entry reached is a firing: it stops
    /// without the glyphs of any one class on the shortest way to it, or of the class it is taken on. Each state keeps
    /// only the step it was first reached by, so a table's size, not its shape, bounds the memory.
    private func stateFirings(type: Int, _ header: Int, _ glyphs: Set<UInt16>) throws(Malformed) -> [Firing] {
        let classCount = try table.u32(header)
        let classTable = header + (try table.u32(header + 4))
        let states = header + (try table.u32(header + 8))
        let entries = header + (try table.u32(header + 12))
        let entrySize = [0: 4, 1: 8, 2: 6, 5: 8][type] ?? 4
        // Glyphs by class: classes 0 (end of text) and 3 (end of line) come without a glyph; a glyph the class table
        // does not name is class 1 (out of bounds).
        var byClass: [Int: Set<UInt16>] = [0: [], 3: []]
        for glyph in glyphs { byClass[try table.lookup(classTable, glyph) ?? 1, default: []].insert(glyph) }
        let classes = byClass.sorted { $0.key < $1.key }
        guard classes.allSatisfy({ $0.key < classCount }) else { throw Malformed() }
        // How each state was first reached: the state before and the glyphs of the class taken (none for a start).
        var reached: [Int: (from: Int, members: Set<UInt16>)?] = [0: nil, 1: nil]
        func path(to state: Int) -> [Set<UInt16>] {
            var steps: [Set<UInt16>] = []
            var current = state
            while let step = reached[current] ?? nil {
                if !step.members.isEmpty { steps.append(step.members) }
                current = step.from
            }
            return steps
        }
        var queue = [0, 1]
        var head = 0
        var found: [Firing] = []
        while head < queue.count {
            let state = queue[head]
            head += 1
            for (glyphClass, members) in classes {
                let entry = entries + entrySize * (try table.u16(states + 2 * (state * classCount + glyphClass)))
                if try acts(type: type, entry: entry) {
                    found.append(Firing(alternatives: path(to: state) + (members.isEmpty ? [] : [members])))
                    guard found.count <= SubstitutionReach.budget else { throw Malformed() }
                }
                let next = try table.u16(entry)
                if reached[next] == nil {
                    reached[next] = .some((state, members))
                    queue.append(next)
                    guard queue.count <= Self.stateLimit else { throw Malformed() }
                }
            }
        }
        return found
    }
}
