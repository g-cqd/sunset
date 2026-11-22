import AemiKernel
import Foundation
import SunsetTestSupport
import Testing

@testable import SunsetCore

/// What receiving an image costs (a probe, run by hand in release: SUNSET_KITTY_PROBE=1): a 1,000 × 1,000 RGBA image
/// (4 MiB) sent as kitty sends it, in 4,096-byte chunks; p50 and p90 of 15 runs. Measured 2026-11-22: 78 ms, then 15 ms
/// (the pending data no longer copied at each chunk), then 4.5 ms (each chunk's bytes appended in one copy).
@Suite("kitty graphics' cost, measured", .enabled(if: ProcessInfo.processInfo.environment["SUNSET_KITTY_PROBE"] != nil))
struct KittyGraphicsSpeedProbe {
    @Test func `a 4 MiB image in 4 KiB chunks`() {
        let encoded = Array(Base64.encodedString([UInt8](repeating: 0x5A, count: 1_000 * 1_000 * 4)).utf8)
        var stream: [UInt8] = []
        var index = 0
        var first = true
        while index < encoded.count {
            let end = min(index + 4_096, encoded.count)
            let more = end < encoded.count ? 1 : 0
            let control = first ? "a=T,i=1,q=2,f=32,s=1000,v=1000,m=\(more)" : "m=\(more)"
            stream += Array("\u{1B}_G\(control);".utf8) + encoded[index ..< end] + Array("\u{1B}\\".utf8)
            first = false
            index = end
        }
        var samples: [Double] = []
        for _ in 0 ..< 15 {
            var t = Terminal(columns: 120, rows: 40)
            t.setCellPixelSize(width: 10, height: 20)
            let spent = Stopwatch.time { stream.withUnsafeBufferPointer { t.feed($0.span) } }
            samples.append(Double(spent.components.attoseconds) / 1e15 + Double(spent.components.seconds) * 1_000)
            precondition(t.screen.graphics.images[1]?.pixels.count == 4_000_000)
        }
        samples.sort()
        print(
            String(
                format: "PROBE 4 MiB RGBA in %d chunks (%.1f MB of escape): p50 %.2f ms, p90 %.2f ms",
                stream.count / 4_100,
                Double(stream.count) / 1e6,
                samples[7],
                samples[13]
            )
        )
    }
}
