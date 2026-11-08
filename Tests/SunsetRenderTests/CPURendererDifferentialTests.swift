import AemiTestKit
import SunsetCore
import Testing

@testable import SunsetRender

@Suite("CPU renderer, differential") struct CPURendererDifferentialTests {
    @Test func `drawing only what changed gives the same pixels as drawing everything`() {
        var random = SeededRNG(seed: 31)
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
                for _ in 0 ..< 1 + random.below(6) {
                    chunk += DifferentialPieces.all[random.below(DifferentialPieces.all.count)]
                }
                history += chunk
                terminal.feed(chunk)
                let blink = random.below(3) != 0
                let textBlink = random.below(4) != 0
                incremental.render(terminal.screen, into: &surface, cursorVisible: blink, textBlinkVisible: textBlink)
                terminal.clearDirty()

                var fresh = Surface(width: size.width, height: size.height)
                CPURenderer(metrics: metrics, glyphs: BoxGlyphSource())
                    .render(terminal.screen, into: &fresh, cursorVisible: blink, textBlinkVisible: textBlink)
                if surface.pixels != fresh.pixels {
                    let first = surface.pixels.indices.first { surface.pixels[$0] != fresh.pixels[$0] } ?? 0
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
