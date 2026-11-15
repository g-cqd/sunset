// Not a benchmark: what shaping runs for ligatures costs on text whose words keep changing (review of 2026-11-15, 2.2 and
// 3.1; task t266). A 120 x 40 screen scrolls lines that look like a log (a hash, a date, a count, a path, a few words): most
// words of a line were never seen before. `CPURenderer.record` (the GPU path's CPU side) is timed for each frame, and the
// glyph bitmaps the renderer holds are counted at the end.
// Usage: GlyphProbe [frames] [on|off] [font]     ligatures on or off (default on), font by name (default Menlo)
// Release only; the Mac's load is whatever it is (ADR-0017): compare the runs of one sitting.
import SunsetCore
import SunsetRender
import SunsetRenderMac

let arguments = CommandLine.arguments
let frames = arguments.count > 1 ? Int(arguments[1]) ?? 4000 : 4000
let ligatures = arguments.count > 2 ? arguments[2] != "off" : true
let fontName = arguments.count > 3 ? arguments[3] : "Menlo"
let source = CoreTextGlyphSource(fontName: fontName, size: 28, features: [], ligatures: ligatures)
var metrics = source.metrics
metrics.paddingX = 4
metrics.paddingY = 4
let size = metrics.surfaceSize(columns: 120, rows: 40)
let renderer = CPURenderer(metrics: metrics, glyphs: source, ligatures: ligatures)
var terminal = Terminal(columns: 120, rows: 40)

// A small generator with a fixed seed: the same lines at every run.
var state: UInt64 = 0x9E37_79B9_7F4A_7C15
@MainActor func next() -> UInt64 {
    state ^= state << 13
    state ^= state >> 7
    state ^= state << 17
    return state
}
let words = ["fix", "the", "renderer", "when", "rows", "scroll", "and", "a", "cursor", "is", "shown", "!=", "->", "=>"]
@MainActor func line(_ index: Int) -> String {
    let hash = String(next() & 0xFFF_FFFF, radix: 16)
    let path = "Sources/Module\(next() % 97)/File\(next() % 9973).swift:\(next() % 4000)"
    let said = (0 ..< 5).map { _ in words[Int(next() % UInt64(words.count))] }.joined(separator: " ")
    return "\(hash) 2026-11-\(10 + index % 20) \(index) \u{1B}[3\(index % 8)m\(path)\u{1B}[0m \(said)\r\n"
}

var samples: [Duration] = []
samples.reserveCapacity(frames)
var most = 0
for index in 0 ..< frames {
    terminal.feed(line(index))
    let start = ContinuousClock.now
    _ = renderer.record(terminal.screen, width: size.width, height: size.height)
    samples.append(ContinuousClock.now - start)
    terminal.clearDirty()
    most = max(most, renderer.glyphStatistics.bytes)
}
let sorted = samples.sorted()
@MainActor func at(_ share: Double) -> Duration { sorted[min(sorted.count - 1, Int(Double(sorted.count) * share))] }
let total = samples.reduce(Duration.zero, +)
let held = renderer.glyphStatistics
print("\(fontName), ligatures \(ligatures ? "on" : "off"), \(frames) frames of one new line each")
print("record: p50 \(at(0.5)), p90 \(at(0.9)), p99 \(at(0.99)), total \(total)")
print("glyph bitmaps at the end: \(held.count), \(held.bytes / 1024) KB; most held during the run: \(most / 1024) KB")
