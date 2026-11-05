import Benchmark
import BenchmarkSupport

// Headless VT model on ~1 MiB of vtebench-equivalent input. One iteration = the whole stream (the metric is per MiB).
// Hot cell widths (T0.1): C8 / C16 / C32. Scrollback (T0.4b): 10,000-row hot ring, with and without the cold structural encoder.
let benchmarks: @Sendable () -> Void = {
    Benchmark.defaultConfiguration = .init(
        metrics: [.wallClock, .instructions, .mallocCountTotal],
        warmupIterations: 3,
        scalingFactor: .one,
        maxDuration: .seconds(4),
        maxIterations: 300,
        thresholds: Thresholds.perSuite
    )
    let streams: [(String, [UInt8])] = [
        ("scrolling", Streams.scrolling), ("scrolling_fullscreen", Streams.fullscreen), ("scrolling_top_region", Streams.topRegion),
        ("dense_cells", Streams.denseCells), ("log", Streams.log), ("unicode", Streams.unicode)
    ]
    for (name, data) in streams {
        func register<C: CellType>(_ t: C.Type, _ label: String, sb: Int = 0, cold: Bool = false) {
            Benchmark("vt/\(name)/\(label)") { benchmark in
                for _ in benchmark.scaledIterations {
                    let m = Model<C>(cols: 120, rows: 40, sbCap: sb, cold: cold)
                    benchmark.startMeasurement()
                    runChunked(m, data)
                    benchmark.stopMeasurement()
                    blackHole(m.cy)
                }
            }
        }
        register(C8.self, "C8")
        if name == "scrolling" || name == "dense_cells" || name == "log" { register(C16.self, "C16"); register(C32.self, "C32") }
        if name == "scrolling" || name == "log" { register(C8.self, "C8+scrollback", sb: 10_000); register(C8.self, "C8+scrollback+cold", sb: 10_000, cold: true) }
    }
}
