import Testing

@testable import SunsetDocuments

/// What must hold of any merge, tried on texts made from seeds (R6, roadmap 0023 step M-e).
@Suite("Three texts merged by pieces: what always holds")
struct ThreeWayMergeLawsTests {
    private static let alphabet = (0 ..< 12).map { "p\($0)" }
    private static let fresh = (0 ..< 40).map { "n\($0)" }

    private struct Case {
        var base: [String]
        var mine: [String]
        var theirs: [String]
    }

    private func cases(seed: UInt64, count: Int = 400) -> [Case] {
        var random = MergeRandom(seed: seed)
        return (0 ..< count)
            .map { _ in
                // Few distinct pieces, so that many repeat, as blank lines do.
                let base = (0 ..< random.below(14)).map { _ in random.pick(Self.alphabet) }
                let mine = random.edited(base, changes: random.below(4), with: Self.fresh + Self.alphabet)
                let theirs = random.edited(base, changes: random.below(4), with: Self.fresh + Self.alphabet)
                return Case(base: base, mine: mine, theirs: theirs)
            }
    }

    private func merged(_ one: Case) -> (text: [String], conflicts: Int) {
        var result = one.mine
        let hunks = ThreeWayMerge(base: one.base, mine: one.mine, theirs: one.theirs).hunks
        for hunk in hunks.reversed() where !hunk.isConflict {
            result.replaceSubrange(hunk.mine, with: one.theirs[hunk.theirs])
        }
        return (result, hunks.count { $0.isConflict })
    }

    @Test func `the hunks are in order, apart, and inside the three texts`() {
        for one in cases(seed: 1) {
            let hunks = ThreeWayMerge(base: one.base, mine: one.mine, theirs: one.theirs).hunks
            var last = (base: 0, mine: 0, theirs: 0)
            for hunk in hunks {
                #expect(hunk.base.lowerBound >= last.base && hunk.base.upperBound <= one.base.count)
                #expect(hunk.mine.lowerBound >= last.mine && hunk.mine.upperBound <= one.mine.count)
                #expect(hunk.theirs.lowerBound >= last.theirs && hunk.theirs.upperBound <= one.theirs.count)
                last = (hunk.base.upperBound, hunk.mine.upperBound, hunk.theirs.upperBound)
            }
        }
    }

    @Test func `with nothing edited here the merge is the disk's text; with nothing changed there it is mine`() {
        for one in cases(seed: 2) {
            let fromDisk = merged(Case(base: one.base, mine: one.base, theirs: one.theirs))
            #expect(fromDisk.text == one.theirs && fromDisk.conflicts == 0)
            let untouched = merged(Case(base: one.base, mine: one.mine, theirs: one.base))
            #expect(untouched.text == one.mine && untouched.conflicts == 0)
            let same = merged(Case(base: one.base, mine: one.mine, theirs: one.mine))
            #expect(same.text == one.mine && same.conflicts == 0)
        }
    }

    @Test func `it does not matter whose edits are called mine`() {
        for one in cases(seed: 3) {
            let here = merged(one)
            let there = merged(Case(base: one.base, mine: one.theirs, theirs: one.mine))
            #expect(here.conflicts == there.conflicts)
            if here.conflicts == 0 { #expect(here.text == there.text, "\(one)") }
        }
    }

    /// The safety of the whole step: a hunk taken by itself only ever replaces pieces that are, here, exactly the pieces of
    /// before. So no piece this side changed or wrote is ever removed without a question.
    @Test func `what is taken from the disk never replaces a piece edited here`() {
        for one in cases(seed: 4, count: 800) {
            for hunk in ThreeWayMerge(base: one.base, mine: one.mine, theirs: one.theirs).hunks where !hunk.isConflict {
                #expect(Array(one.mine[hunk.mine]) == Array(one.base[hunk.base]), "\(one)")
                #expect(Array(one.theirs[hunk.theirs]) != Array(one.base[hunk.base]), "\(one)")
            }
        }
    }

    @Test func `a conflict is where both sides changed, differently`() {
        for one in cases(seed: 5, count: 800) {
            for hunk in ThreeWayMerge(base: one.base, mine: one.mine, theirs: one.theirs).hunks where hunk.isConflict {
                let base = Array(one.base[hunk.base])
                let mine = Array(one.mine[hunk.mine])
                let theirs = Array(one.theirs[hunk.theirs])
                #expect(mine != base && theirs != base && mine != theirs, "\(one)")
            }
        }
    }

    /// Blank lines, rules, the rows of a log: pieces that repeat give nothing to hold on to. Past the budget they are not
    /// compared every way.
    @Test func `a long run of pieces that repeat is compared place by place, or counts as replaced whole`() {
        let base = [String](repeating: "same", count: 3000)
        var mine = base
        mine[10] = "mine"
        mine[2990] = "mine too"
        var theirs = base
        theirs[1500] = "theirs"
        // As many pieces as before: each is compared with the one at its place, and the three changes are apart.
        let apart = ThreeWayMerge(base: base, mine: mine, theirs: theirs).hunks
        #expect(
            apart == [
                ThreeWayMerge.Hunk(base: 1500 ..< 1501, mine: 1500 ..< 1501, theirs: 1500 ..< 1501, isConflict: false)
            ]
        )
        // One more piece here: the run counts as replaced whole, and a change there inside it is a conflict, never a guess.
        mine.insert("put in", at: 20)
        let whole = ThreeWayMerge(base: base, mine: mine, theirs: theirs).hunks
        #expect(whole.count == 1 && whole[0].isConflict && whole[0].mine == 10 ..< 2992 && whole[0].base == 10 ..< 2991)
        // With the budget for it the same texts merge.
        #expect(
            ThreeWayMerge(base: base, mine: mine, theirs: theirs, limit: 100_000_000).hunks
                .allSatisfy { !$0.isConflict }
        )
    }

    /// Blocks of a document are mostly one of a kind: those hold the comparison together whatever the length.
    @Test func `edits far apart in a long text of distinct pieces merge, without the budget being spent`() {
        let base = (0 ..< 50_000).map { "block \($0)" }
        var mine = base
        mine[10] = "mine"
        mine.insert("put in here", at: 40_000)
        mine.remove(at: 49_000)
        var theirs = base
        theirs[25_000] = "theirs"
        theirs.insert("put in there", at: 30)
        let hunks = ThreeWayMerge(base: base, mine: mine, theirs: theirs, limit: 16).hunks
        #expect(hunks.count == 2 && hunks.allSatisfy { !$0.isConflict })
    }
}
