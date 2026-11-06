import Benchmark
import BenchmarkSupport
import SunsetCore
import SunsetRender

// The CPU renderer (ADR-0024) on a 120x40 screen of coloured text, with box glyphs (the renderer's own cost, not a font rasteriser's). Instructions and
// mallocs are the gate (ADR-0019). Full frame, one changed row, and only the cursor moving.

private func filledTerminal() -> Terminal {
    var terminal = Terminal(columns: 120, rows: 40)
    for row in 0 ..< 40 {
        terminal.feed("\u{1B}[\(row + 1);1H")
        for column in 0 ..< 12 {
            terminal.feed("\u{1B}[3\((row + column) % 8)m\u{1B}[4\((row * 3 + column) % 8)mword\(column) ")
        }
    }
    terminal.clearDirty()
    return terminal
}

/// Glyphs with antialiased coverage, like a font's (about 60 % of the pixels empty, 15 % solid, the rest in between), made from the scalar so that the same
/// text gives the same pixels: the cost of blending a glyph, which `BoxGlyphSource` (solid boxes) does not show.
private struct CoverageGlyphSource: GlyphSource {
    func glyph(for text: String, bold: Bool, italic: Bool, columns: Int, metrics: RenderMetrics) -> GlyphBitmap? {
        guard let scalar = text.unicodeScalars.first, scalar.value > 0x20 else { return nil }
        let width = metrics.cellWidth * columns - 4
        let height = metrics.cellHeight - 8
        var state = UInt64(scalar.value) &* 0x9E37_79B9_7F4A_7C15
        var coverage = [UInt8](repeating: 0, count: width * height)
        for index in coverage.indices {
            state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
            let draw = Int(state >> 33) % 100
            coverage[index] = draw < 60 ? 0 : draw < 75 ? 255 : UInt8(truncatingIfNeeded: state >> 40)
        }
        return GlyphBitmap(width: width, height: height, left: 2, top: 4, coverage: coverage)
    }
}

let benchmarks: @Sendable () -> Void = {
    Benchmark.defaultConfiguration = .init(
        metrics: [.wallClock, .instructions, .mallocCountTotal],
        warmupIterations: 3,
        scalingFactor: .one,
        maxDuration: .seconds(4),
        maxIterations: 300,
        thresholds: Thresholds.perSuite
    )
    let metrics = RenderMetrics(cellWidth: 8, cellHeight: 16)
    let size = metrics.surfaceSize(columns: 120, rows: 40)

    Benchmark("present/surface to bytes (1640x976 pixels, a retina window)") { benchmark in
        let surface = Surface(width: 1640, height: 976)
        benchmark.startMeasurement()
        for _ in benchmark.scaledIterations {
            blackHole(surface.rgbaBytes.count)
        }
        benchmark.stopMeasurement()
    }

    Benchmark("render/full frame (120x40, 960x640 pixels)") { benchmark in
        let terminal = filledTerminal()
        var surface = Surface(width: size.width, height: size.height)
        let renderer = CPURenderer(metrics: metrics, glyphs: BoxGlyphSource())
        renderer.render(terminal.screen, into: &surface)
        benchmark.startMeasurement()
        for _ in benchmark.scaledIterations {
            renderer.invalidate()
            renderer.render(terminal.screen, into: &surface)
        }
        benchmark.stopMeasurement()
        blackHole(surface.pixels[0])
    }

    Benchmark("render/one row changed") { benchmark in
        var terminal = filledTerminal()
        var surface = Surface(width: size.width, height: size.height)
        let renderer = CPURenderer(metrics: metrics, glyphs: BoxGlyphSource())
        renderer.render(terminal.screen, into: &surface)
        var tick = 0
        benchmark.startMeasurement()
        for _ in benchmark.scaledIterations {
            tick += 1
            terminal.feed("\u{1B}[20;1H\u{1B}[3\(tick % 8)mchanged \(tick % 10)")
            renderer.render(terminal.screen, into: &surface)
            terminal.clearDirty()
        }
        benchmark.stopMeasurement()
        blackHole(surface.pixels[0])
    }

    Benchmark("render/only the cursor moves") { benchmark in
        var terminal = filledTerminal()
        var surface = Surface(width: size.width, height: size.height)
        let renderer = CPURenderer(metrics: metrics, glyphs: BoxGlyphSource())
        renderer.render(terminal.screen, into: &surface)
        var tick = 0
        benchmark.startMeasurement()
        for _ in benchmark.scaledIterations {
            tick += 1
            terminal.feed("\u{1B}[\(1 + tick % 39);\(1 + tick % 100)H")
            renderer.render(terminal.screen, into: &surface)
            terminal.clearDirty()
        }
        benchmark.stopMeasurement()
        blackHole(surface.pixels[0])
    }

    // A retina window: cells of 17x37 pixels (JetBrains Mono at 14 pt, scale 2), 120x40, antialiased glyphs. What a full redraw costs in the app.
    let retina = RenderMetrics(cellWidth: 17, cellHeight: 37)
    let retinaSize = retina.surfaceSize(columns: 120, rows: 40)
    for (name, filled) in [("blank", false), ("text", true)] {
        Benchmark("render/retina full frame, \(name) (120x40, \(retinaSize.width)x\(retinaSize.height) pixels)") {
            benchmark in
            let terminal = filled ? filledTerminal() : Terminal(columns: 120, rows: 40)
            var surface = Surface(width: retinaSize.width, height: retinaSize.height)
            let renderer = CPURenderer(metrics: retina, glyphs: CoverageGlyphSource())
            renderer.render(terminal.screen, into: &surface)
            benchmark.startMeasurement()
            for _ in benchmark.scaledIterations {
                renderer.invalidate()
                renderer.render(terminal.screen, into: &surface)
            }
            benchmark.stopMeasurement()
            blackHole(surface.pixels[0])
        }
    }
}
