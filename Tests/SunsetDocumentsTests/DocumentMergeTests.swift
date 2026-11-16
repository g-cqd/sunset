import Testing

@testable import SunsetDocuments

/// The merge of a change on disk into a text edited here, as the edits to make in that text (R6, roadmap 0023 step M-e):
/// where the disk's blocks go, and where both changed a block, with what the disk says there. In UTF-16 units of the text
/// edited here, which is what its editors count in.
@Suite("A change on disk merged into edits made here")
struct DocumentMergeTests {
    private typealias Change = DocumentMerge.Change
    private typealias Conflict = DocumentMerge.Conflict

    private let base = "# Title\n\nFirst paragraph.\n\nSecond paragraph.\n\nThird paragraph.\n"

    @Test func `a block changed on disk and another edited here: the disk's is put in, mine stays`() {
        let mine = base.replacing("First paragraph.", with: "First paragraph, edited here.")
        let theirs = base.replacing("Third paragraph.", with: "Third paragraph, changed on disk.")
        let merge = DocumentMerge(base: base, mine: mine, theirs: theirs, kind: .markdown)
        #expect(merge.conflicts.isEmpty && !merge.isWhole)
        #expect(merge.changes.count == 1)
        #expect(
            merge.merged(mine)
                == "# Title\n\nFirst paragraph, edited here.\n\nSecond paragraph.\n\nThird paragraph, changed on disk.\n"
        )
    }

    @Test func `the same block changed on both sides is a conflict: mine stays, and the disk's is kept beside it`() {
        let mine = base.replacing("Second paragraph.", with: "Second, mine.")
        let theirs = base.replacing("Second paragraph.", with: "Second, theirs.")
            .replacing("# Title", with: "# Renamed")
        let merge = DocumentMerge(base: base, mine: mine, theirs: theirs, kind: .markdown)
        #expect(merge.merged(mine) == mine.replacing("# Title", with: "# Renamed"))
        let start = "# Title\n\nFirst paragraph.\n\n".utf16.count
        #expect(
            merge.conflicts == [
                Conflict(
                    range: start ..< start + "Second, mine.\n\n".utf16.count,
                    base: "Second paragraph.\n\n",
                    theirs: "Second, theirs.\n\n"
                )
            ]
        )
    }

    @Test func `ranges count UTF-16 units, as the editors do`() {
        let base = "\u{1F600} one\n\ncaf\u{E9}\n\nlast\n"
        let mine = base.replacing("last", with: "last, mine")
        let theirs = base.replacing("caf\u{E9}", with: "th\u{E9} \u{1F375}")
        let merge = DocumentMerge(base: base, mine: mine, theirs: theirs, kind: .markdown)
        let start = "\u{1F600} one\n\n".utf16.count
        #expect(start == 8)
        #expect(merge.changes == [Change(range: start ..< start + 6, replacement: "th\u{E9} \u{1F375}\n\n")])
        #expect(merge.merged(mine) == "\u{1F600} one\n\nth\u{E9} \u{1F375}\n\nlast, mine\n")
    }

    @Test func `a block removed on disk goes; one removed here and changed there is asked about`() {
        let removed = base.replacing("Second paragraph.\n\n", with: "")
        let mine = base.replacing("First", with: "1st")
        #expect(
            DocumentMerge(base: base, mine: mine, theirs: removed, kind: .markdown).merged(mine)
                == "# Title\n\n1st paragraph.\n\nThird paragraph.\n"
        )
        let changed = base.replacing("Second paragraph.", with: "Second, changed there.")
        let merge = DocumentMerge(base: base, mine: removed, theirs: changed, kind: .markdown)
        let start = "# Title\n\nFirst paragraph.\n\n".utf16.count
        #expect(merge.changes.isEmpty)
        #expect(
            merge.conflicts
                == [
                    Conflict(
                        range: start ..< start,
                        base: "Second paragraph.\n\n",
                        theirs: "Second, changed there.\n\n"
                    )
                ]
        )
    }

    @Test func `text and diagrams merge by lines`() {
        let base = "one\ntwo\nthree\nfour\n"
        let merge = DocumentMerge(
            base: base,
            mine: "ONE\ntwo\nthree\nfour\n",
            theirs: "one\ntwo\nthree\nFOUR\nfive\n",
            kind: .text
        )
        #expect(merge.conflicts.isEmpty && merge.merged("ONE\ntwo\nthree\nfour\n") == "ONE\ntwo\nthree\nFOUR\nfive\n")
    }

    /// A block is what it is because of what stands before it: an indented line is code after a paragraph and a part of the
    /// item after a list item. Blocks taken from two texts can so read as other blocks once together; then nothing is merged
    /// by itself and the whole text is one question.
    @Test func `blocks that would read differently once together are not merged: the whole text is one conflict`() {
        let base = "A\n\nB\n"
        let mine = "A\n\n    B2\n"
        let theirs = "- A\n\nB\n"
        let merge = DocumentMerge(base: base, mine: mine, theirs: theirs, kind: .markdown)
        #expect(merge.isWhole && merge.changes.isEmpty)
        #expect(merge.conflicts == [Conflict(range: 0 ..< mine.utf16.count, base: base, theirs: theirs)])
        #expect(merge.merged(mine) == mine)
    }

    @Test func `nothing to do when the disk says what is here, or what it said before`() {
        let mine = base + "More.\n"
        #expect(DocumentMerge(base: base, mine: mine, theirs: mine, kind: .markdown) == DocumentMerge())
        #expect(DocumentMerge(base: base, mine: mine, theirs: base, kind: .markdown) == DocumentMerge())
    }

    /// The laws of the pieces, on real texts: made from the scraps a parser trips on, edited on both sides.
    @Test(arguments: [DocumentKind.markdown, .text])
    func `whatever the texts: mine is never cut into, and what is merged reads as the blocks that were chosen`(
        kind: DocumentKind
    ) {
        var random = MergeRandom(seed: 0xD15C + UInt64(kind.rawValue.count))
        var merged = 0
        for _ in 0 ..< 400 {
            let base = random.document(scraps: 10)
            let pieces = TextPieces.of(base, kind: kind).map { String($0.text) }
            let mine = random.edited(pieces, changes: random.below(3), with: MergeRandom.scraps).joined()
            let theirs = random.edited(pieces, changes: random.below(3), with: MergeRandom.scraps).joined()
            let merge = DocumentMerge(base: base, mine: mine, theirs: theirs, kind: kind)
            let result = merge.merged(mine)
            if theirs == base || theirs == mine { #expect(result == mine && merge.conflicts.isEmpty) }
            if mine == base { #expect(result == theirs && merge.conflicts.isEmpty, "\(base.debugDescription)") }
            // Every range is inside mine and on a piece's edge: nothing is ever cut inside a block.
            let edges = Set(
                TextPieces.of(mine, kind: kind).reduce(into: [0]) { $0.append($0[$0.count - 1] + $1.text.utf16.count) }
            )
            for range in merge.changes.map(\.range) + merge.conflicts.map(\.range) {
                #expect(edges.contains(range.lowerBound) && edges.contains(range.upperBound))
            }
            if !merge.changes.isEmpty { merged += 1 }
        }
        #expect(merged > 20)
    }
}
