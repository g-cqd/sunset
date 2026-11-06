import SunsetCore
import Testing

@testable import SunsetRender

private struct Random64 {
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

private let esc = "\u{1B}"

/// Pieces of output that between them touch every part of the renderer: text, wide characters, clusters, colours, attributes, cursor moves, scrolling,
/// erasing, cursor shapes, reverse video, palette changes, the alternate screen.
private let pieces: [String] = [
    "hello", " ", "x", "日本", "e\u{301}", "👍🏽", "\r\n", "\r\n", "\n", "\r", "\u{08}", "\t",
    "\(esc)[1m", "\(esc)[3m", "\(esc)[4m", "\(esc)[4:3m", "\(esc)[7m", "\(esc)[2m", "\(esc)[9m", "\(esc)[53m",
    "\(esc)[0m",
    "\(esc)[31m", "\(esc)[42m", "\(esc)[38;5;123m", "\(esc)[48;2;10;200;30m", "\(esc)[58;2;200;0;0m",
    "\(esc)[H", "\(esc)[3;4H", "\(esc)[2;1H", "\(esc)[A", "\(esc)[3C", "\(esc)[2D",
    "\(esc)[K", "\(esc)[1K", "\(esc)[2K", "\(esc)[J", "\(esc)[1J", "\(esc)[2J", "\(esc)[2@", "\(esc)[2P", "\(esc)[L",
    "\(esc)[M", "\(esc)[S", "\(esc)[T",
    "\(esc)[3 q", "\(esc)[5 q", "\(esc)[2 q", "\(esc)[?25l", "\(esc)[?25h", "\(esc)[?5h", "\(esc)[?5l",
    "\(esc)]4;1;#336699\u{7}", "\(esc)]104\u{7}", "\(esc)[?1049h", "\(esc)[?1049l", "\(esc)[2;4r", "\(esc)[r"
]

@Suite("CPU renderer, differential") struct CPURendererDifferentialTests {
    @Test func `drawing only what changed gives the same pixels as drawing everything`() {
        var random = Random64(state: 31)
        let metrics = RenderMetrics(cellWidth: 8, cellHeight: 16)
        for round in 0 ..< 120 {
            let columns = 6 + random.below(14)
            let rows = 3 + random.below(6)
            var terminal = Terminal(columns: columns, rows: rows)
            let size = metrics.surfaceSize(columns: columns, rows: rows)
            var surface = Surface(width: size.width, height: size.height)
            let incremental = CPURenderer(metrics: metrics, glyphs: BoxGlyphSource())
            var history = ""
            for _ in 0 ..< 25 {
                var chunk = ""
                for _ in 0 ..< 1 + random.below(6) { chunk += pieces[random.below(pieces.count)] }
                history += chunk
                terminal.feed(chunk)
                let blink = random.below(3) != 0
                incremental.render(terminal.screen, into: &surface, cursorVisible: blink)
                terminal.clearDirty()

                var fresh = Surface(width: size.width, height: size.height)
                CPURenderer(metrics: metrics, glyphs: BoxGlyphSource())
                    .render(terminal.screen, into: &fresh, cursorVisible: blink)
                if surface.pixels != fresh.pixels {
                    let first = zip(surface.pixels.indices, zip(surface.pixels, fresh.pixels))
                        .first { $0.1.0 != $0.1.1 }!
                        .0
                    Issue.record(
                        "round \(round): pixel \(first % surface.width),\(first / surface.width) differs after \(history.debugDescription)"
                    )
                    return
                }
            }
        }
    }

    @Test func `a resize draws everything again`() {
        let metrics = RenderMetrics(cellWidth: 8, cellHeight: 16)
        var terminal = Terminal(columns: 10, rows: 4)
        terminal.feed("hello\r\n\(esc)[31mworld")
        let renderer = CPURenderer(metrics: metrics, glyphs: BoxGlyphSource())
        var size = metrics.surfaceSize(columns: 10, rows: 4)
        var surface = Surface(width: size.width, height: size.height)
        renderer.render(terminal.screen, into: &surface)
        terminal.clearDirty()
        terminal.resize(columns: 6, rows: 3)
        size = metrics.surfaceSize(columns: 6, rows: 3)
        surface = Surface(width: size.width, height: size.height)
        renderer.render(terminal.screen, into: &surface)
        var fresh = Surface(width: size.width, height: size.height)
        CPURenderer(metrics: metrics, glyphs: BoxGlyphSource()).render(terminal.screen, into: &fresh)
        #expect(surface.pixels == fresh.pixels)
    }

    @Test func `a frame with nothing dirty and the cursor still draws nothing`() {
        let metrics = RenderMetrics(cellWidth: 8, cellHeight: 16)
        var terminal = Terminal(columns: 10, rows: 4)
        terminal.feed("abc")
        let size = metrics.surfaceSize(columns: 10, rows: 4)
        var surface = Surface(width: size.width, height: size.height)
        let renderer = CPURenderer(metrics: metrics, glyphs: BoxGlyphSource())
        renderer.render(terminal.screen, into: &surface)
        terminal.clearDirty()
        // Scribble on the surface: an untouched frame must leave the scribble alone (only changed rows are redrawn).
        surface.pixels[0] = 0xFF12_3456
        renderer.render(terminal.screen, into: &surface)
        #expect(surface.pixels[0] == 0xFF12_3456)
    }
}
