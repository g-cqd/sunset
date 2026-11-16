internal import Foundation

/// A change on disk merged into a text edited here (roadmap 0023 step M-e), as what to do in that text: the blocks to take
/// from the disk, and the blocks both changed, each with what the disk says there. Ranges are UTF-16 units of the text
/// edited here as it is before any of it is done, as its editors count.
///
/// Blocks are read from each text by the parser, and a block is what it is because of what stands before it (an indented
/// line is code after a paragraph, a part of the item after a list item). So what was merged is read again: when it does not
/// read as exactly the blocks that were chosen, nothing is merged and the whole text is one conflict.
struct DocumentMerge: Equatable, Sendable {
    struct Change: Equatable, Sendable {
        var range: Range<Int>
        var replacement: String
    }

    struct Conflict: Equatable, Sendable {
        var range: Range<Int>
        /// What these blocks were before either side changed them.
        var base: String
        /// What the disk says there now; empty when it removed them.
        var theirs: String
    }

    /// In order, apart.
    private(set) var changes: [Change] = []
    private(set) var conflicts: [Conflict] = []
    /// Nothing could be merged block by block: the one conflict is the whole text.
    private(set) var isWhole = false

    init() {}

    /// - Complexity: O(the three texts) to cut and compare them when they differ in few places (`PieceEdits`), and O(the
    ///   merged text) to read it again.
    init(base: String, mine: String, theirs: String, kind: DocumentKind) {
        guard !theirs.utf8.elementsEqual(base.utf8), !theirs.utf8.elementsEqual(mine.utf8) else { return }
        let before = TextPieces.of(base, kind: kind)
        let here = TextPieces.of(mine, kind: kind)
        let there = TextPieces.of(theirs, kind: kind)
        var starts = [0]
        starts.reserveCapacity(here.count + 1)
        for piece in here { starts.append(starts[starts.count - 1] + piece.text.utf16.count) }
        var expected = here
        for hunk in ThreeWayMerge(base: before, mine: here, theirs: there).hunks.reversed() {
            let range = starts[hunk.mine.lowerBound] ..< starts[hunk.mine.upperBound]
            let text = there[hunk.theirs].map(\.text).joined()
            if hunk.isConflict {
                conflicts.insert(
                    Conflict(range: range, base: before[hunk.base].map(\.text).joined(), theirs: text),
                    at: 0
                )
            } else {
                changes.insert(Change(range: range, replacement: text), at: 0)
                expected.replaceSubrange(hunk.mine, with: there[hunk.theirs])
            }
        }
        guard !changes.isEmpty, TextPieces.of(merged(mine), kind: kind) != expected else { return }
        changes = []
        conflicts = [Conflict(range: 0 ..< starts[starts.count - 1], base: base, theirs: theirs)]
        isWhole = true
    }

    /// The same, off the caller's actor: a long text is read four times by the parser.
    @concurrent
    static func made(base: String, mine: String, theirs: String, kind: DocumentKind) async -> DocumentMerge {
        DocumentMerge(base: base, mine: mine, theirs: theirs, kind: kind)
    }

    /// `mine` with the changes done.
    func merged(_ mine: String) -> String {
        guard !changes.isEmpty else { return mine }
        let text = NSMutableString(string: mine)
        for change in changes.reversed() {
            let range = NSRange(location: change.range.lowerBound, length: change.range.count)
            text.replaceCharacters(in: range, with: change.replacement)
        }
        return text as String
    }
}
