// Not a benchmark: runs the CPU renderer's frame walk (`CPURenderer.record`, the GPU path's CPU side, or `render`, the CPU backend) on a scrolling
// 120x40 screen for `frames` frames, so `sample` can attribute its time and `/usr/bin/time -l` count its instructions (renderer plan 2026-11-08,
// item 3). Usage: RecordProbe [frames] [record|render|feed]   (`feed` only parses: subtract it.)
import SunsetCore
import SunsetRender
import SunsetRenderMac

let arguments = CommandLine.arguments
let count = arguments.count > 1 ? Int(arguments[1]) ?? 5000 : 5000
let mode = arguments.count > 2 ? arguments[2] : "record"
let source = CoreTextGlyphSource(fontName: "Menlo", size: 28, features: [])
var metrics = source.metrics
metrics.paddingX = 4
metrics.paddingY = 4
let size = metrics.surfaceSize(columns: 120, rows: 40)
let renderer = CPURenderer(metrics: metrics, glyphs: source)
var surface = Surface(width: size.width, height: size.height)
var terminal = Terminal(columns: 120, rows: 40)
func line(_ index: Int) -> String {
    "line \(index) flood \u{1B}[3\(index % 8)mcoloured\u{1B}[0m " + String(repeating: "abcdefghij", count: 9) + "\r\n"
}
var frames = 0
var ops = 0
let start = ContinuousClock.now
while frames < count {
    terminal.feed(line(frames))
    if mode == "render" {
        renderer.render(terminal.screen, into: &surface)
    } else if mode == "record" {
        ops &+= renderer.record(terminal.screen, width: size.width, height: size.height).ops.count
    }
    terminal.clearDirty()
    frames += 1
}
let elapsed = ContinuousClock.now - start
print("\(mode): \(frames) frames, \(elapsed / frames) per frame, \(ops / max(frames, 1)) ops per frame")
