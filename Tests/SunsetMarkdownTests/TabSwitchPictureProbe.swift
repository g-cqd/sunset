import AppKit
import Foundation
import SunsetDocuments
import SunsetPane
import SunsetTestSupport
import Testing

@testable import SunsetMarkdown

/// A probe, not a test (n56, t298): what leaving a document costs, because a hidden document is pictured at once, on the main
/// thread. Runs only with SUNSET_PROBE=1, in release (`swift test -c release -Xswiftc -enable-testing`); prints percentiles.
@MainActor
@Suite("Document picture probe", .serialized, .enabled(if: ProcessInfo.processInfo.environment["SUNSET_PROBE"] != nil))
struct TabSwitchPictureProbe {
    @Test(arguments: [("short", 10), ("page", 80), ("long", 300)], ["rendered", "source"])
    func `leaving a document: the picture it takes`(size: (String, Int), view: String) throws {
        let root = NSTemporaryDirectory() + "probe-\(UUID().uuidString)"
        try FileManager.default.createDirectory(atPath: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(atPath: root) }
        var text = "# Title\n\n"
        for index in 0 ..< size.1 {
            text +=
                "## Section \(index)\n\nSome words **bold** and `code` and a [link](https://example.org/\(index)) in a paragraph that goes on.\n\n- one\n- two\n\n"
        }
        try text.write(toFile: root + "/n.md", atomically: true, encoding: .utf8)
        let pane = try #require(
            DocumentContent(
                PaneDescriptor(kind: DocumentContent.kind, state: ["file": root + "/n.md", "view": view]),
                documents: OpenDocuments(store: nil)
            )
        )
        pane.drawnSize = CGSize(width: 1100, height: 800)
        var samples: [Double] = []
        for _ in 0 ..< 30 {
            let elapsed = Stopwatch.time { pane.takePicture() }
            samples.append(Double(elapsed.components.attoseconds) / 1e15 + Double(elapsed.components.seconds) * 1000)
        }
        samples.sort()
        print(
            "PROBE document \(size.0) (\(size.1) sections) \(view): p50=\(String(format: "%.2f", samples[15])) ms "
                + "p95=\(String(format: "%.2f", samples[28])) ms max=\(String(format: "%.2f", samples[29])) ms"
        )
        pane.stop()
    }
}
