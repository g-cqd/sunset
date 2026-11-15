// Not a benchmark: what the first frame costs after a terminal's renderer has rested (review of 2026-11-15, 3.2; task t267).
// At rest the Metal renderer keeps the surface on screen and lets the others go; the next frame makes a surface again and
// brings it up to the one shown. This times `present` for a one-line change on a window-sized grid (200 x 55 cells, Menlo
// 28: about 3400 x 1900 pixels), `frames` times each way:
//   steady: frame after frame, two surfaces alternating;
//   rested: `rest()` before each frame.
// Usage: RestProbe [frames]. Release only; the Mac's load is whatever it is (ADR-0017): compare the two columns of one run.
import Foundation
import SunsetCore
import SunsetRender
import SunsetRenderMac
import SunsetRenderMetal

let frames = CommandLine.arguments.count > 1 ? Int(CommandLine.arguments[1]) ?? 300 : 300
let source = CoreTextGlyphSource(fontName: "Menlo", size: 28, features: [])
var metrics = source.metrics
metrics.paddingX = 4
metrics.paddingY = 4
guard let renderer = MetalSurfaceRenderer(metrics: metrics, glyphs: source, ligatures: false) else {
    print("no Metal device")
    exit(1)
}
var terminal = Terminal(columns: 200, rows: 55)
for row in 0 ..< 55 { terminal.feed("row \(row) " + String(repeating: "abcdefghij", count: 18) + "\r\n") }

func percentiles(_ samples: [Duration]) -> String {
    let sorted = samples.sorted()
    func at(_ share: Double) -> Duration { sorted[min(sorted.count - 1, Int(Double(sorted.count) * share))] }
    return "p50 \(at(0.5)), p90 \(at(0.9)), p99 \(at(0.99)), max \(sorted[sorted.count - 1])"
}

@MainActor func run(rested: Bool) async -> [Duration] {
    var samples: [Duration] = []
    for index in 0 ..< frames {
        terminal.feed("\u{1B}[10;1Hframe \(index) of \(rested ? "rested" : "steady")")
        if rested { await renderer.rest() }
        let start = ContinuousClock.now
        _ = await renderer.present(terminal.screen, cursorVisible: true, textBlinkVisible: true, view: FrameView())
        samples.append(ContinuousClock.now - start)
        terminal.clearDirty()
    }
    return samples
}

_ = await run(rested: false)
let steady = await run(rested: false)
let rested = await run(rested: true)
let size = metrics.surfaceSize(columns: 200, rows: 55)
print(
    "surface \(size.width) x \(size.height) pixels (\(size.width * size.height * 4 / 1_000_000) MB), \(frames) frames each"
)
print("steady: \(percentiles(steady))")
print("rested: \(percentiles(rested))")
