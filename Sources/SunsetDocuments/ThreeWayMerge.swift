/// The merge of two edits of one text, by pieces. A wrong merge is silent damage, so what is done without a question is
/// narrow: pieces that only the other side replaced, removed or put in. Where both sides touched the same pieces, put
/// pieces in at the same place, or one put pieces in among those the other replaced, it is a conflict, unless both made
/// the same of it.
///
/// Changes to pieces side by side are both kept: a piece is a block, a unit by itself (lines, which are not, are merged the
/// same way, and are checked the same way by `DocumentMerge`). Pieces put in exactly where a changed run begins go before
/// it, and where it ends after it, whichever side is which.
struct ThreeWayMerge: Equatable, Sendable {
    /// What to do in my text: put `theirs` where `mine` is (these pieces are, here, exactly `base`), or ask.
    struct Hunk: Equatable, Sendable {
        var base: Range<Int>
        var mine: Range<Int>
        var theirs: Range<Int>
        var isConflict: Bool
    }

    /// How many pairs of pieces each side may compare in full, between the pieces that are plainly the same: a thousand by a
    /// thousand, some 35 ms at the worst (measured, release). Past it a long run that matches nothing is one change.
    static let limit = 1_000_000

    /// In order, apart.
    private(set) var hunks: [Hunk] = []

    init<Piece: Hashable>(base: [Piece], mine: [Piece], theirs: [Piece], limit: Int = ThreeWayMerge.limit) {
        let here = PieceEdits(base: base, side: mine, limit: limit)
        let there = PieceEdits(base: base, side: theirs, limit: limit)
        var all = here.edits.map { (edit: $0.base, isMine: true) } + there.edits.map { (edit: $0.base, isMine: false) }
        // A run that is only pieces put in comes before a run that begins at the same place: it is then never taken for a
        // part of what an earlier run of the other side reaches.
        all.sort { first, second in
            (first.edit.lowerBound, first.edit.isEmpty ? 0 : 1) < (second.edit.lowerBound, second.edit.isEmpty ? 0 : 1)
        }
        var group: [(edit: Range<Int>, isMine: Bool)] = []
        func close() {
            guard let low = group.map(\.edit.lowerBound).min(), let high = group.map(\.edit.upperBound).max(),
                group.contains(where: { !$0.isMine })
            else { return }
            let point = low == high
            let mineRange = (point ? here.low[low] : here.high[low]) ..< (point ? here.high[low] : here.low[high])
            let theirRange = (point ? there.low[low] : there.high[low]) ..< (point ? there.high[low] : there.low[high])
            let both = group.contains { $0.isMine }
            if both, mine[mineRange].elementsEqual(theirs[theirRange]) { return }
            hunks.append(Hunk(base: low ..< high, mine: mineRange, theirs: theirRange, isConflict: both))
        }
        for item in all {
            if group.contains(where: { $0.isMine != item.isMine && Self.collide($0.edit, item.edit) }) {
                group.append(item)
            } else {
                close()
                group = [item]
            }
        }
        close()
    }

    /// Two runs, one of each side, that cannot both be done without choosing: they share a piece of before, or one is
    /// pieces put in strictly among the other's, or both are pieces put in at the same place.
    private static func collide(_ first: Range<Int>, _ second: Range<Int>) -> Bool {
        if first.isEmpty, second.isEmpty { return first.lowerBound == second.lowerBound }
        return first.lowerBound < second.upperBound && second.lowerBound < first.upperBound
    }
}
