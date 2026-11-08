import AemiTestKit
import SunsetCore
import Testing

@testable import SunsetRender

/// What a GPU backend gets: frames recorded one after the other and applied to the surface it keeps. Replayed on the CPU, they must give the pixels of drawing
/// the screen afresh, frame after frame.
@Suite("Recorded frames, differential") struct RecordedDifferentialTests {
    @Test func `recorded frames applied one after the other give the pixels of drawing everything`() {
        var random = SeededRNG(seed: 47)
        let metrics = RenderMetrics(cellWidth: 8, cellHeight: 16)
        for round in 0 ..< 120 {
            let columns = 6 + random.below(14)
            let rows = 3 + random.below(6)
            var terminal = Terminal(columns: columns, rows: rows)
            let size = metrics.surfaceSize(columns: columns, rows: rows)
            var replayed = Surface(width: size.width, height: size.height)
            let recorder = CPURenderer(metrics: metrics, glyphs: BoxGlyphSource())
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
                recorder.record(
                    terminal.screen,
                    width: size.width,
                    height: size.height,
                    cursorVisible: blink,
                    textBlinkVisible: textBlink
                )
                .replay(onto: &replayed)
                terminal.clearDirty()

                var fresh = Surface(width: size.width, height: size.height)
                CPURenderer(metrics: metrics, glyphs: BoxGlyphSource())
                    .render(terminal.screen, into: &fresh, cursorVisible: blink, textBlinkVisible: textBlink)
                guard replayed.pixels == fresh.pixels else {
                    let first = replayed.pixels.indices.first { replayed.pixels[$0] != fresh.pixels[$0] } ?? 0
                    Issue.record(
                        "round \(round): pixel \(first % size.width),\(first / size.width) differs after \(history.debugDescription)"
                    )
                    return
                }
            }
        }
    }
}
