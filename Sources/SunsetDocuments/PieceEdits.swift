/// What one side did to the pieces of before (roadmap 0023 step M-e): the runs of pieces it replaced, removed or put in,
/// each between two pieces it left alone, and where every place between two pieces of before falls in its own text.
struct PieceEdits: Sendable {
    /// Pieces `base` of before are, on this side, pieces `side`. Either can be empty (put in, removed), not both.
    struct Edit: Equatable, Sendable {
        var base: Range<Int>
        var side: Range<Int>
    }

    /// In order, apart. A run of pieces replaced by as many is one edit for each piece; any other run is one edit, with at
    /// least one untouched piece before the next.
    private(set) var edits: [Edit] = []
    /// For the place before piece `g` of before (`count` is the end): where it falls on this side, the pieces put in at that
    /// very place counted after it (`low`) or before it (`high`). Not meaningful strictly inside an edit.
    private(set) var low: [Int]
    private(set) var high: [Int]

    /// - Parameters:
    ///   - base: the pieces of before.
    ///   - side: this side's.
    ///   - limit: how many pairs of pieces may be compared in full (`PieceMatching`).
    /// - Complexity: O(n log n + d^2) for d pieces that differ, never more than O(n log n + limit).
    init<Piece: Hashable>(base: [Piece], side: [Piece], limit: Int) {
        let image = PieceMatching.image(base: base, side: side, budget: limit)
        low = image.enumerated().map { $1 ?? -1 } + [side.count]
        high = low
        var baseStart = 0
        var sideStart = 0
        for place in 0 ... base.count {
            guard let target = place == base.count ? side.count : image[place] else { continue }
            if baseStart < place, place - baseStart == target - sideStart {
                // As many pieces as before: each is the piece at its place, changed. A conflict is then about one block.
                for offset in 0 ..< place - baseStart {
                    let (from, to) = (baseStart + offset, sideStart + offset)
                    (low[from], high[from]) = (to, to)
                    // The same piece at the same place is no change, however the two texts were compared.
                    if base[from] != side[to] { edits.append(Edit(base: from ..< from + 1, side: to ..< to + 1)) }
                }
            } else if baseStart < place || sideStart < target {
                edits.append(Edit(base: baseStart ..< place, side: sideStart ..< target))
                low[baseStart] = sideStart
                high[baseStart] = baseStart < place ? sideStart : target
            }
            baseStart = place + 1
            sideStart = target + 1
        }
    }
}
