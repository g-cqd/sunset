import Darwin
import Metal
import SunsetCore
import SunsetRender
import SunsetRenderMac
import Testing

@testable import SunsetRenderMetal

@Suite("probe (temporary)", .serialized) struct ZZStudyProbe {
    func us(_ d: Duration) -> Double { (Double(d.components.attoseconds) / 1e18 + Double(d.components.seconds)) * 1e6 }

    @Test func `study`() throws {
        let source = CoreTextGlyphSource(fontName: "Menlo", size: 28, features: [])
        for (columns, rows) in [(120, 40), (300, 80)] {
            var metrics = source.metrics
            metrics.paddingX = 4
            metrics.paddingY = 4
            let compositor = try #require(MetalCompositor())
            let size = metrics.surfaceSize(columns: columns, rows: rows)
            let target = try #require(compositor.makeTarget(width: size.width, height: size.height))
            func text(_ i: Int) -> String {
                "line \(i) flood \u{1B}[3\(i % 8)mcoloured\u{1B}[0m "
                    + String(repeating: "abcdefghij", count: columns / 10 - 3)
            }
            let workloads: [(String, (inout Terminal, Int) -> Void)] = [
                ("scroll 1 line", { t, i in t.feed(text(i) + "\r\n") }),
                ("scroll 5 lines", { t, i in for k in 0 ..< 5 { t.feed(text(i * 5 + k) + "\r\n") } }),
                ("type 1 char", { t, i in t.feed(String(UnicodeScalar(UInt8(97 + i % 26)))) }),
                ("cursor blink", { _, _ in }),
                (
                    "full redraw",
                    { t, i in
                        t.feed("\u{1B}[H")
                        for r in 0 ..< rows { t.feed("\u{1B}[\(r + 1);1H" + text(i + r) + "\u{1B}[K") }
                    }
                )
            ]
            for (name, step) in workloads {
                let cpu = CPURenderer(metrics: metrics, glyphs: source)
                let rec = CPURenderer(metrics: metrics, glyphs: source)
                var surface = Surface(width: size.width, height: size.height)
                var t1 = Terminal(columns: columns, rows: rows)
                var t2 = Terminal(columns: columns, rows: rows)
                for i in 0 ..< rows * 2 {
                    t1.feed(text(i) + "\r\n")
                    t2.feed(text(i) + "\r\n")
                }
                cpu.render(t1.screen, into: &surface)
                t1.clearDirty()
                try compositor.apply(rec.record(t2.screen, width: size.width, height: size.height), to: target)
                t2.clearDirty()
                let n = 200
                var cpuT = 0.0
                var recT = 0.0
                var applyT = 0.0
                var gpuT = 0.0
                var feedT = 0.0
                var feedHeldT = 0.0
                var applyCPU = 0.0
                var ops = 0
                var glyphOps = 0
                var rowsPx = 0
                var unique = Set<ObjectIdentifier>().count
                var seen = Set<ObjectIdentifier>()
                for i in 0 ..< n {
                    var c = ContinuousClock.now
                    step(&t1, 1000 + i)
                    feedT += us(ContinuousClock.now - c)
                    let held = t2.screen  // a snapshot is outstanding while the next bytes are parsed
                    c = ContinuousClock.now
                    step(&t2, 1000 + i)
                    feedHeldT += us(ContinuousClock.now - c)
                    _ = held
                    c = ContinuousClock.now
                    cpu.render(t1.screen, into: &surface, cursorVisible: i % 2 == 0)
                    cpuT += us(ContinuousClock.now - c)
                    t1.clearDirty()
                    c = ContinuousClock.now
                    let f = rec.record(t2.screen, width: size.width, height: size.height, cursorVisible: i % 2 == 0)
                    recT += us(ContinuousClock.now - c)
                    t2.clearDirty()
                    for op in f.ops {
                        if case .glyph(let b, _, _, _, _, _, _, _) = op {
                            glyphOps += 1
                            seen.insert(ObjectIdentifier(b))
                        }
                    }
                    ops += f.ops.count
                    rowsPx += f.changedPixelRows?.count ?? 0
                    c = ContinuousClock.now
                    let cpu0 = clock_gettime_nsec_np(CLOCK_THREAD_CPUTIME_ID)
                    try compositor.apply(f, to: target)
                    applyT += us(ContinuousClock.now - c)
                    applyCPU += Double(clock_gettime_nsec_np(CLOCK_THREAD_CPUTIME_ID) - cpu0) / 1000
                    gpuT += compositor.lastGPUSeconds * 1e6
                }
                unique = seen.count
                func f(_ x: Double) -> String { String(Int(x / Double(n))) }
                print(
                    "PROBE \(columns)x\(rows) \(name): ops \(ops / n) (glyph \(glyphOps / n), distinct bitmaps in run \(unique)), px rows \(rowsPx / n)/\(size.height) | feed \(f(feedT)) us, with snapshot held \(f(feedHeldT)) | CPU render \(f(cpuT)) | record \(f(recT)) + apply \(f(applyT)) (gpu exec \(f(gpuT)), thread CPU in apply \(f(applyCPU)))"
                )
            }
        }
    }
}
