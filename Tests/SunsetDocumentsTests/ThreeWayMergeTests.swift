import Testing

@testable import SunsetDocuments

/// The merge of two edits of one text, piece by piece. A wrong merge is silent damage, so what it may do by itself is
/// narrow: pieces only one side changed, removed or put in take that side's; pieces both sides touched are a conflict,
/// unless both made the same of them. Nothing else is decided here.
@Suite("Three texts merged by pieces")
struct ThreeWayMergeTests {
    private typealias Hunk = ThreeWayMerge.Hunk

    private func merge(_ base: String, _ mine: String, _ theirs: String) -> [Hunk] {
        ThreeWayMerge(base: Array(base), mine: Array(mine), theirs: Array(theirs)).hunks
    }

    /// Mine with the hunks that are not conflicts done.
    private func merged<Piece: Hashable>(_ base: [Piece], _ mine: [Piece], _ theirs: [Piece]) -> [Piece] {
        var result = mine
        for hunk in ThreeWayMerge(base: base, mine: mine, theirs: theirs).hunks.reversed() where !hunk.isConflict {
            result.replaceSubrange(hunk.mine, with: theirs[hunk.theirs])
        }
        return result
    }

    @Test func `nothing changed on disk, or the same change on both sides: nothing to do`() {
        #expect(merge("abc", "aXc", "abc").isEmpty)
        #expect(merge("abc", "abc", "abc").isEmpty)
        #expect(merge("abc", "aXc", "aXc").isEmpty)
        #expect(merge("abc", "ac", "ac").isEmpty)
        #expect(merge("", "", "").isEmpty)
    }

    @Test func `what only the disk changed is taken: a piece replaced, removed, put in`() {
        #expect(merge("abc", "abc", "aXc") == [Hunk(base: 1 ..< 2, mine: 1 ..< 2, theirs: 1 ..< 2, isConflict: false)])
        #expect(merge("abc", "abc", "ac") == [Hunk(base: 1 ..< 2, mine: 1 ..< 2, theirs: 1 ..< 1, isConflict: false)])
        #expect(merge("abc", "abc", "abXc") == [Hunk(base: 2 ..< 2, mine: 2 ..< 2, theirs: 2 ..< 3, isConflict: false)])
        #expect(merge("", "", "X") == [Hunk(base: 0 ..< 0, mine: 0 ..< 0, theirs: 0 ..< 1, isConflict: false)])
    }

    @Test func `changes apart, with a piece neither touched between them, are both kept`() {
        #expect(
            merge("abcde", "aXcde", "abcYe") == [Hunk(base: 3 ..< 4, mine: 3 ..< 4, theirs: 3 ..< 4, isConflict: false)]
        )
        #expect(merged(Array("abcde"), Array("aXcde"), Array("abcYe")) == Array("aXcYe"))
        #expect(merged(Array("abcde"), Array("Zabcde"), Array("abcdeQ")) == Array("ZabcdeQ"))
        #expect(merged(Array("abcde"), Array("bcde"), Array("abcd")) == Array("bcd"))
    }

    @Test func `the same pieces changed differently are a conflict, and nothing is taken there`() {
        #expect(merge("abc", "aXc", "aYc") == [Hunk(base: 1 ..< 2, mine: 1 ..< 2, theirs: 1 ..< 2, isConflict: true)])
        // Removed here, changed there; and the other way.
        #expect(merge("abc", "ac", "aYc") == [Hunk(base: 1 ..< 2, mine: 1 ..< 1, theirs: 1 ..< 2, isConflict: true)])
        #expect(merge("abc", "aXc", "ac") == [Hunk(base: 1 ..< 2, mine: 1 ..< 2, theirs: 1 ..< 1, isConflict: true)])
        // Put in at the same place.
        #expect(merge("ac", "aXc", "aYc") == [Hunk(base: 1 ..< 1, mine: 1 ..< 2, theirs: 1 ..< 2, isConflict: true)])
        #expect(merge("", "X", "Y") == [Hunk(base: 0 ..< 0, mine: 0 ..< 1, theirs: 0 ..< 1, isConflict: true)])
    }

    /// A block is a unit: the one after it edited elsewhere is another matter (lines, which are not, would conflict here).
    @Test func `changes to pieces side by side are both kept, each in its place`() {
        #expect(merged(Array("abcd"), Array("aXcd"), Array("abYd")) == Array("aXYd"))
        #expect(merged(Array("abcd"), Array("abYd"), Array("aXcd")) == Array("aXYd"))
        // Put in just before, or just after, a piece the disk changed or removed.
        #expect(merged(Array("abc"), Array("aXbc"), Array("aBc")) == Array("aXBc"))
        #expect(merged(Array("abc"), Array("abXc"), Array("aBc")) == Array("aBXc"))
        #expect(merged(Array("abc"), Array("aXbc"), Array("ac")) == Array("aXc"))
        #expect(merged(Array("abc"), Array("aBc"), Array("abXc")) == Array("aBXc"))
    }

    @Test func `pieces put in among the ones the other side replaced, and runs that overlap, are conflicts`() {
        #expect(
            merge("abcd", "abXcd", "aYd") == [Hunk(base: 1 ..< 3, mine: 1 ..< 4, theirs: 1 ..< 2, isConflict: true)]
        )
        #expect(
            merge("abcd", "aYd", "abXcd") == [Hunk(base: 1 ..< 3, mine: 1 ..< 2, theirs: 1 ..< 4, isConflict: true)]
        )
        // Two pieces made one here, the second of them changed there, and the next one too: that one is taken.
        #expect(
            merge("abcde", "aXde", "abYYe") == [
                Hunk(base: 1 ..< 3, mine: 1 ..< 2, theirs: 1 ..< 3, isConflict: true),
                Hunk(base: 3 ..< 4, mine: 2 ..< 3, theirs: 3 ..< 4, isConflict: false)
            ]
        )
    }

    /// As many pieces after as before: each is taken as the piece it stands for. A question is then about one block, not
    /// about every block that changed next to it.
    @Test func `a run replaced by as many pieces is as many changes, each asked about or taken by itself`() {
        #expect(
            merge("abcde", "aXXde", "abYYe") == [
                Hunk(base: 2 ..< 3, mine: 2 ..< 3, theirs: 2 ..< 3, isConflict: true),
                Hunk(base: 3 ..< 4, mine: 3 ..< 4, theirs: 3 ..< 4, isConflict: false)
            ]
        )
        #expect(merged(Array("abcde"), Array("aXXde"), Array("abcYZ")) == Array("aXXYZ"))
    }

    @Test func `a conflict does not stop what is apart from it`() {
        let hunks = merge("abcdefg", "aXcdefg", "aYcdeZg")
        #expect(
            hunks == [
                Hunk(base: 1 ..< 2, mine: 1 ..< 2, theirs: 1 ..< 2, isConflict: true),
                Hunk(base: 5 ..< 6, mine: 5 ..< 6, theirs: 5 ..< 6, isConflict: false)
            ]
        )
    }

    @Test func `repeated pieces are not mistaken for one another across a change`() {
        // Blank lines and rules repeat in any document.
        #expect(merged(Array("a-b-c-d"), Array("a-B-c-d"), Array("a-b-c-D")) == Array("a-B-c-D"))
        #expect(merged(Array("----"), Array("--X--"), Array("----Y")) == Array("--X--Y"))
    }
}
