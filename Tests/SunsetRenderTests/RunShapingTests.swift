import SunsetCore
import Testing

@testable import SunsetRender

private let esc = "\u{1B}"
private let metrics = RenderMetrics(cellWidth: 8, cellHeight: 16)
private let white = RGB(229, 229, 229)
private let black = RGB(0, 0, 0)

/// A source that shapes runs: a run containing "->" is one glyph over the whole run (a ligature), any other run is drawn as the box glyphs one by one.
private final class RunSource: GlyphSource {
    nonisolated(unsafe) var runs: [String] = []
    nonisolated(unsafe) var singles: [String] = []
    var shapesRuns: Bool { true }

    func glyph(for text: String, bold: Bool, italic: Bool, columns: Int, metrics: RenderMetrics) -> GlyphBitmap? {
        singles.append(text)
        return BoxGlyphSource().glyph(for: text, bold: bold, italic: italic, columns: columns, metrics: metrics)
    }

    func glyph(forRun text: String, bold: Bool, italic: Bool, cells: Int, metrics: RenderMetrics) -> GlyphBitmap? {
        runs.append(text + (bold ? "|b" : ""))
        let width = cells * metrics.cellWidth
        if text.contains("->") {
            return GlyphBitmap(
                width: width - 4,
                height: metrics.cellHeight - 4,
                left: 2,
                top: 2,
                coverage: [UInt8](repeating: 255, count: (width - 4) * (metrics.cellHeight - 4))
            )
        }
        var canvas = [UInt8](repeating: 0, count: width * metrics.cellHeight)
        for (index, _) in text.unicodeScalars.enumerated() {
            for y in 2 ..< metrics.cellHeight - 2 {
                for x in 2 ..< metrics.cellWidth - 2 { canvas[y * width + index * metrics.cellWidth + x] = 255 }
            }
        }
        return GlyphBitmap(width: width, height: metrics.cellHeight, left: 0, top: 0, coverage: canvas)
    }
}

private struct Rig {
    var terminal: Terminal
    var surface: Surface
    let renderer: CPURenderer
    let source: RunSource

    init(ligatures: Bool, columns: Int = 40) {
        source = RunSource()
        terminal = Terminal(columns: columns, rows: 3)
        let size = metrics.surfaceSize(columns: columns, rows: 3)
        surface = Surface(width: size.width, height: size.height)
        renderer = CPURenderer(metrics: metrics, glyphs: source, ligatures: ligatures)
    }

    mutating func frame(_ text: String, cursorVisible: Bool = false) {
        terminal.feed(text)
        renderer.render(terminal.screen, into: &surface, cursorVisible: cursorVisible)
        terminal.clearDirty()
    }

    func pixel(_ column: Int, _ x: Int, _ y: Int, row: Int = 0) -> RGB { surface[column * 8 + x, row * 16 + y] }
}

@Suite("Run shaping") struct RunShapingTests {
    @Test func `without the option the source is never asked to shape a run`() {
        var rig = Rig(ligatures: false)
        rig.frame("a->b")
        #expect(rig.source.runs.isEmpty)
        #expect(rig.source.singles == ["a", "-", ">", "b"])
    }

    @Test func `a run is shaped as one piece, and a ligature spans its cells`() {
        var rig = Rig(ligatures: true)
        rig.frame("a->b")
        #expect(rig.source.runs == ["a->b"])
        #expect(rig.source.singles.isEmpty)
        // The ligature glyph is solid across the cell boundaries, where separate boxes would leave a gap.
        #expect(rig.pixel(0, 7, 8) == white && rig.pixel(1, 0, 8) == white)
        var plain = Rig(ligatures: false)
        plain.frame("a->b")
        #expect(plain.pixel(0, 7, 8) == black)
    }

    @Test func `runs end at spaces, style changes, wide characters, built-in glyphs and clusters`() {
        var rig = Rig(ligatures: true)
        rig.frame("ab cd\(esc)[1mef\(esc)[0mgh日本ij─kl e\u{301}f")
        #expect(rig.source.runs == ["ab", "cd", "ef|b", "gh", "ij", "kl"])
        #expect(
            rig.source.singles.contains("日") && rig.source.singles.contains("本")
                && rig.source.singles.contains("e\u{301}")
        )
        #expect(!rig.source.singles.contains("─"), "line drawing is the renderer's own")
    }

    @Test func `a single cell is not a run`() {
        var rig = Rig(ligatures: true)
        rig.frame("a b")
        #expect(rig.source.runs.isEmpty)
        #expect(rig.source.singles == ["a", " ", "b"])
    }

    @Test func `the same text is shaped once`() {
        var rig = Rig(ligatures: true)
        rig.frame("word word other word")
        #expect(rig.source.runs == ["word", "other"])
    }

    @Test func `the cursor splits a run and is drawn on its own cell`() {
        var rig = Rig(ligatures: true)
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
        var rig = Rig(ligatures: true, columns: 60)
        rig.frame(String(repeating: "x", count: 40))
        #expect(rig.source.runs == [String(repeating: "x", count: 32), String(repeating: "x", count: 8)])
    }

    @Test func `backgrounds and decorations still draw per cell under a run`() {
        var rig = Rig(ligatures: true)
        rig.frame("\(esc)[44;4mab")
        #expect(rig.pixel(0, 0, 0) == RGB(0, 0, 238))
        #expect(rig.pixel(1, 0, 0) == RGB(0, 0, 238))
        #expect(rig.pixel(1, 0, metrics.underlineY) == white)
    }

    @Test func `drawing only what changed matches drawing everything with runs on`() {
        var random = SplitMix(state: 77)
        let pieces = [
            "ab", "->", "=>", "x", " ", "日", "\r\n", "\(esc)[1m", "\(esc)[0m", "\(esc)[31m", "\(esc)[3;2H", "\(esc)[K",
            "\(esc)[2P", "e\u{301}", "─", "\(esc)[7m", "\(esc)[4m"
        ]
        for round in 0 ..< 80 {
            var terminal = Terminal(columns: 12, rows: 4)
            let size = metrics.surfaceSize(columns: 12, rows: 4)
            var surface = Surface(width: size.width, height: size.height)
            let incremental = CPURenderer(metrics: metrics, glyphs: RunSource(), ligatures: true)
            for _ in 0 ..< 20 {
                var chunk = ""
                for _ in 0 ..< 1 + random.below(5) { chunk += pieces[random.below(pieces.count)] }
                terminal.feed(chunk)
                let blink = random.below(2) == 0
                incremental.render(terminal.screen, into: &surface, cursorVisible: blink)
                terminal.clearDirty()
                var fresh = Surface(width: size.width, height: size.height)
                CPURenderer(metrics: metrics, glyphs: RunSource(), ligatures: true)
                    .render(terminal.screen, into: &fresh, cursorVisible: blink)
                if surface.pixels != fresh.pixels {
                    Issue.record("round \(round): differs after \(chunk.debugDescription)")
                    return
                }
            }
        }
    }
}

private struct SplitMix {
    var state: UInt64
    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
    mutating func below(_ bound: Int) -> Int { Int(next() % UInt64(bound)) }
}
