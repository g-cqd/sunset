import Benchmark
import BenchmarkSupport
import SunsetCore

// The VT parser alone (roadmap 0003) on ~1 MiB of synthetic streams: what it costs to recognise bytes, with a sink that only counts.
// One iteration = the whole stream. The gate is instructions and mallocs (ADR-0019); wall clock is reported.

private struct Generator {
    var state: UInt64 = 0x1234_5678
    mutating func next(_ bound: Int) -> Int {
        state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
        return Int((state >> 33) % UInt64(bound))
    }
}

private func ascii(_ size: Int) -> [UInt8] {
    var out: [UInt8] = []
    out.reserveCapacity(size + 100)
    var generator = Generator()
    while out.count < size {
        for _ in 0 ..< 79 { out.append(UInt8(0x20 + generator.next(95))) }
        out.append(contentsOf: [13, 10])
    }
    return out
}

private func sgrDense(_ size: Int) -> [UInt8] {
    var out: [UInt8] = []
    var generator = Generator()
    while out.count < size {
        out.append(
            contentsOf: Array("\u{1B}[38;2;\(generator.next(256));\(generator.next(256));\(generator.next(256))m".utf8)
        )
        for _ in 0 ..< 1 + generator.next(4) { out.append(UInt8(0x41 + generator.next(26))) }
        if generator.next(40) == 0 { out.append(contentsOf: Array("\u{1B}[0m\r\n".utf8)) }
    }
    return out
}

/// What vtebench's `scrolling` writes: a line feed after every two bytes, so every line scrolls the screen.
private func lineFeeds(_ size: Int) -> [UInt8] {
    var bytes: [UInt8] = []
    bytes.reserveCapacity(size)
    while bytes.count < size { bytes += [0x79, 0x0A] }
    return bytes
}

/// What vtebench's `scrolling_fullscreen` writes: lines of 120 letters, each ended by the pseudo-terminal's CR LF.
private func fullLines(_ size: Int) -> [UInt8] {
    var bytes: [UInt8] = []
    bytes.reserveCapacity(size + 130)
    var letter: UInt8 = 0x41
    while bytes.count < size {
        bytes += [UInt8](repeating: letter, count: 120) + [0x0D, 0x0A]
        letter = letter == 0x5A ? 0x41 : letter + 1
    }
    return bytes
}

private func cursorMoves(_ size: Int) -> [UInt8] {
    var out: [UInt8] = []
    var generator = Generator()
    while out.count < size {
        out.append(contentsOf: Array("\u{1B}[\(1 + generator.next(40));\(1 + generator.next(120))H*".utf8))
    }
    return out
}

private func unicode(_ size: Int) -> [UInt8] {
    var out: [UInt8] = []
    var generator = Generator()
    let pool = Array("日本語のテキストéàüñ€—…😀🎉 abc".unicodeScalars)
    while out.count < size {
        out.append(contentsOf: Array(String(pool[generator.next(pool.count)]).utf8))
        if generator.next(60) == 0 { out.append(contentsOf: [13, 10]) }
    }
    return out
}

private func titles(_ size: Int) -> [UInt8] {
    var out: [UInt8] = []
    var generator = Generator()
    while out.count < size {
        out.append(contentsOf: Array("\u{1B}]0;window title \(generator.next(100000))\u{7}text\r\n".utf8))
    }
    return out
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
    let size = 1 << 20
    let streams: [(String, [UInt8])] = [
        ("ascii", ascii(size)), ("sgr_truecolor", sgrDense(size)), ("cursor_moves", cursorMoves(size)),
        ("unicode", unicode(size)), ("line_feeds", lineFeeds(size)), ("full_lines", fullLines(size)),
        ("osc_titles", titles(size))
    ]
    for (name, data) in streams {
        Benchmark("parser/\(name) (1 MiB)") { benchmark in
            var counter = ParseCounter()
            benchmark.startMeasurement()
            for _ in benchmark.scaledIterations {
                data.withUnsafeBufferPointer { counter.feed($0.span) }
            }
            benchmark.stopMeasurement()
            blackHole(counter.printable &+ counter.csis)
        }
    }
    // The same bytes into a whole terminal (parser + screen, 120x40): what a program's output costs end to end, headless.
    for (name, data) in streams {
        Benchmark("terminal/\(name) (1 MiB, 120x40)") { benchmark in
            var terminal = Terminal(columns: 120, rows: 40)
            data.withUnsafeBufferPointer { terminal.feed($0.span) }
            benchmark.startMeasurement()
            for _ in benchmark.scaledIterations {
                data.withUnsafeBufferPointer { terminal.feed($0.span) }
            }
            benchmark.stopMeasurement()
            blackHole(terminal.screen.cursorRow)
        }
    }
    // The app's pattern under a flood: output arrives in reads of 8 KiB, and a snapshot of the screen is held while the next read is parsed (the window's last
    // frame). With a full history (100 000 lines) a snapshot that shares the history must not make the next write copy it.
    if let flood = streams.first(where: { $0.0 == "ascii" })?.1 {
        Benchmark("terminal/flood with a snapshot per read (100k lines of history)") { benchmark in
            var terminal = Terminal(columns: 120, rows: 40)
            for _ in 0 ..< 110 { flood.withUnsafeBufferPointer { terminal.feed($0.span) } }
            var held = terminal.screen
            benchmark.startMeasurement()
            for _ in benchmark.scaledIterations {
                var offset = 0
                while offset < flood.count {
                    let end = min(offset + 8192, flood.count)
                    flood[offset ..< end].withUnsafeBufferPointer { terminal.feed($0.span) }
                    held = terminal.screen
                    terminal.clearDirty()
                    offset = end
                }
            }
            benchmark.stopMeasurement()
            blackHole(held.scrollbackCount)
        }
    }
}
