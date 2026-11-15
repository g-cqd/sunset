import SunsetCore
import Testing

@testable import SunsetRender

/// A run in which shaping changes nothing is its characters side by side: it is drawn from their glyphs, and no bitmap of
/// the run is made or kept (the review of 2026-11-15, 2.2 and 3.1: with ligatures on, every new word was a new bitmap).
extension RunShapingTests {
    func plainRig() -> RunShapingRig {
        let rig = RunShapingRig(ligatures: true)
        rig.source.saysPlain = true
        return rig
    }

    @Test func `a run that shaping does not change is drawn from its characters, and keeps no bitmap`() {
        var rig = plainRig()
        rig.frame("word other word")
        #expect(rig.source.runs.isEmpty, "no run was drawn as one piece")
        #expect(Set(rig.source.singles) == Set("wordothe".map(String.init)))
        #expect(rig.renderer.glyphStatistics.count == 7, "one glyph per character seen: w o r d t h e")

        var unshaped = RunShapingRig(ligatures: false)
        unshaped.frame("word other word")
        #expect(rig.surface.pixels == unshaped.surface.pixels, "the same picture as with ligatures off")
    }

    @Test func `the source is asked once about each run, and a run with a ligature is still one piece`() {
        var rig = plainRig()
        rig.frame("word a->b word\r\nword a->b")
        #expect(rig.source.asked == ["word", "a->b"])
        #expect(rig.source.runs == ["a->b"])
        #expect(rig.pixel(5, 7, 8) == white && rig.pixel(6, 0, 8) == white, "the ligature spans its cells")
        let held = rig.renderer.glyphStatistics.count
        rig.frame("\r\nword word word a->b")
        #expect(rig.renderer.glyphStatistics.count == held, "nothing new is kept for text seen before")
    }

    @Test func `new words by the thousand keep no more bitmaps than their characters`() {
        var rig = plainRig()
        for index in 0 ..< 2000 { rig.frame("n\(index) x\(index * 7)\r\n") }
        #expect(rig.renderer.glyphStatistics.count <= 12, "ten digits, n and x: \(rig.renderer.glyphStatistics.count)")

        var shaped = RunShapingRig(ligatures: true)
        for index in 0 ..< 2000 { shaped.frame("n\(index) x\(index * 7)\r\n") }
        #expect(
            shaped.renderer.glyphStatistics.count > 3000,
            "a source that cannot say keeps a bitmap a run, as before"
        )
    }

    @Test func `the bitmaps kept are bounded by their bytes, and the picture stays right`() {
        var rig = RunShapingRig(ligatures: true)
        rig.renderer.glyphTableByteLimit = 4000
        var most = 0
        for index in 0 ..< 300 {
            rig.frame("\u{1B}[H\u{1B}[2Jrun\(index) a->b\(index)")
            most = max(most, rig.renderer.glyphStatistics.bytes)
        }
        // A frame's own bitmaps come on top of the bound: the table starts again between frames, not within one.
        #expect(most < 4000 + 2 * 16 * 8 * 16, "\(most) bytes were held")
        var fresh = RunShapingRig(ligatures: true)
        fresh.frame("\u{1B}[H\u{1B}[2Jrun299 a->b299")
        #expect(rig.surface.pixels == fresh.surface.pixels)
    }
}
