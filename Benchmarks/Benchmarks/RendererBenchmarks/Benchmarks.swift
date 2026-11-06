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
}
