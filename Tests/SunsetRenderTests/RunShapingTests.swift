import AemiTestKit
import SunsetCore
import Testing

@testable import SunsetRender

@Suite("Run shaping") struct RunShapingTests {
    @Test func `without the option the source is never asked to shape a run`() {
        var rig = RunShapingRig(ligatures: false)
        rig.frame("a->b")
        #expect(rig.source.runs.isEmpty)
        #expect(rig.source.singles == ["a", "-", ">", "b"])
    }

    @Test func `a run is shaped as one piece, and a ligature spans its cells`() {
        var rig = RunShapingRig(ligatures: true)
        rig.frame("a->b")
        #expect(rig.source.runs == ["a->b"])
        #expect(rig.source.singles.isEmpty)
        // The ligature glyph is solid across the cell boundaries, where separate boxes would leave a gap.
        #expect(rig.pixel(0, 7, 8) == white && rig.pixel(1, 0, 8) == white)
        var plain = RunShapingRig(ligatures: false)
        plain.frame("a->b")
        #expect(plain.pixel(0, 7, 8) == black)
    }

    @Test func `runs end at spaces, style changes, wide characters, built-in glyphs and clusters`() {
        var rig = RunShapingRig(ligatures: true)
        rig.frame("ab cd\(esc)[1mef\(esc)[0mgh日本ij─kl e\u{301}f")
        #expect(rig.source.runs == ["ab", "cd", "ef|b", "gh", "ij", "kl"])
        #expect(
            rig.source.singles.contains("日") && rig.source.singles.contains("本")
                && rig.source.singles.contains("e\u{301}")
        )
        #expect(!rig.source.singles.contains("─"), "line drawing is the renderer's own")
    }

    @Test func `a single cell is not a run`() {
        var rig = RunShapingRig(ligatures: true)
        rig.frame("a b")
        #expect(rig.source.runs.isEmpty)
        // A blank in the default style draws nothing, so the source is not asked for it.
        #expect(rig.source.singles == ["a", "b"])
    }

    @Test func `the same text is shaped once`() {
        var rig = RunShapingRig(ligatures: true)
        rig.frame("word word other word")
        #expect(rig.source.runs == ["word", "other"])
    }

    @Test func `the cursor splits a run and is drawn on its own cell`() {
        var rig = RunShapingRig(ligatures: true)
        rig.frame("abcde\(esc)[1;3H", cursorVisible: true)
        #expect(rig.source.runs == ["ab", "de"])
        #expect(rig.source.singles == ["c"])
        #expect(rig.pixel(2, 0, 0) == white)
        rig.frame("\(esc)[1;5H", cursorVisible: true)
        // The cursor moved to the last cell: the first four are one run again.
        #expect(rig.source.runs.last == "abcd")
        #expect(rig.pixel(2, 0, 0) == black)
    }

    @Test func `a long run is cut at the longest the shaper takes`() {
        var rig = RunShapingRig(ligatures: true, columns: 60)
        rig.frame(String(repeating: "x", count: 40))
        #expect(rig.source.runs == [String(repeating: "x", count: 32), String(repeating: "x", count: 8)])
    }

    @Test func `backgrounds and decorations still draw per cell under a run`() {
        var rig = RunShapingRig(ligatures: true)
        rig.frame("\(esc)[44;4mab")
        #expect(rig.pixel(0, 0, 0) == RGB(0, 0, 238))
        #expect(rig.pixel(1, 0, 0) == RGB(0, 0, 238))
        #expect(rig.pixel(1, 0, metrics.underlineY) == white)
    }

    @Test func `drawing only what changed matches drawing everything with runs on`() {
        var random = SeededRNG(seed: 77)
        let pieces = [
            "ab", "->", "=>", "x", " ", "日", "\r\n", "\(esc)[1m", "\(esc)[0m", "\(esc)[31m", "\(esc)[3;2H", "\(esc)[K",
            "\(esc)[2P", "e\u{301}", "─", "\(esc)[7m", "\(esc)[4m"
        ]
        for round in 0 ..< 80 {
            var terminal = Terminal(columns: 12, rows: 4)
            let size = metrics.surfaceSize(columns: 12, rows: 4)
            var surface = Surface(width: size.width, height: size.height)
            let incremental = CPURenderer(metrics: metrics, glyphs: RunShapingSource(), ligatures: true)
            for _ in 0 ..< 20 {
                var chunk = ""
                for _ in 0 ..< 1 + random.below(5) { chunk += pieces[random.below(pieces.count)] }
                terminal.feed(chunk)
                let blink = random.below(2) == 0
                incremental.render(terminal.screen, into: &surface, cursorVisible: blink)
                terminal.clearDirty()
                var fresh = Surface(width: size.width, height: size.height)
                CPURenderer(metrics: metrics, glyphs: RunShapingSource(), ligatures: true)
                    .render(terminal.screen, into: &fresh, cursorVisible: blink)
                if surface.pixels != fresh.pixels {
                    Issue.record("round \(round): differs after \(chunk.debugDescription)")
                    return
                }
            }
        }
    }
}
