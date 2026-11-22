import Foundation
import SunsetCore
import SunsetTestSupport
import Testing

@testable import SunsetRender

/// What drawing images costs the CPU renderer (a probe, run by hand in release: SUNSET_IMAGE_PROBE=1): a full 120 × 40 frame of
/// text, without an image and with a 640 × 480 one over it (`render`, every row drawn again); and the first frame that shows a
/// scaled image (read and scaled once). p50 and p90 of 31 runs.
@Suite("Image drawing's cost, measured", .enabled(if: ProcessInfo.processInfo.environment["SUNSET_IMAGE_PROBE"] != nil))
struct ImageRenderSpeedProbe {
    private static let text = (0 ..< 40).map { "line \($0) " + String(repeating: "abcdefghij", count: 11) }
        .joined(separator: "\r\n")

    private func milliseconds(_ duration: Duration) -> Double {
        Double(duration.components.attoseconds) / 1e15 + Double(duration.components.seconds) * 1_000
    }

    private func report(_ name: String, _ samples: [Double]) {
        let sorted = samples.sorted()
        print(
            String(
                format: "PROBE %@: p50 %.3f ms, p90 %.3f ms",
                name,
                sorted[sorted.count / 2],
                sorted[sorted.count * 9 / 10]
            )
        )
    }

    private func fullFrames(_ rig: inout CPURendererRig) -> [Double] {
        (0 ..< 31)
            .map { _ in
                rig.renderer.invalidate()
                let renderer = rig.renderer
                let screen = rig.terminal.screen
                return milliseconds(
                    Stopwatch.time { renderer.render(screen, into: &rig.surface, cursorVisible: false) }
                )
            }
    }

    @Test func `a full frame, without and with an image; the first frame of a scaled one`() {
        var plain = CPURendererRig(120, 40)
        plain.terminal.feed(Self.text)
        report("full frame, text only", fullFrames(&plain))
        var shown = CPURendererRig(120, 40)
        shown.terminal.feed(
            "\u{1B}[H" + KittyImages.show(id: 1, width: 640, height: 480, rgba: [200, 30, 30, 200]) + Self.text
        )
        precondition(shown.terminal.screen.graphics.placements.count == 1, "the image is placed")
        report("full frame, text and a 640 × 480 image", fullFrames(&shown))
        precondition(shown.surface[600, 8] != plain.surface[600, 8], "and drawn")
        let first = (0 ..< 31)
            .map { run in
                var rig = CPURendererRig(120, 40)
                rig.terminal.feed(
                    KittyImages.show(
                        id: 1,
                        width: 640,
                        height: 480,
                        rgba: [200, 30, 30, 200],
                        options: "c=\(60 + run % 2)"
                    )
                )
                let spent = milliseconds(Stopwatch.time { rig.frame(cursorVisible: false) })
                precondition(rig.renderer.shownImages.count == 1, "the image is drawn")
                return spent
            }
        report("first frame of a 640 × 480 image scaled to 60 columns", first)
    }
}
