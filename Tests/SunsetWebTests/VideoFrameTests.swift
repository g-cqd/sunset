import AemiTestKit
import AppKit
import Foundation
import SunsetTestSupport
import Testing
import WebKit

@testable import SunsetWeb
@testable import SunsetWebModel

/// Picture in picture reaches a video in a frame of its own (n126: Fox News's player is in a frame from another origin;
/// probed 2026-11-23). The frame that plays is known to Sunset, and Sunset's script runs there. (Not the system's picture
/// in picture window itself: a test does not open one on the screen.)
@MainActor @Suite("A video in a frame of its own", .timeLimit(.minutes(1)))
struct VideoFrameTests {
    @Test func `the frame whose video plays is the one picture in picture works in`() async throws {
        let page = WebContent(url: nil, settings: WebSettings(applicationName: "x"))
        page.setState(focused: false, visible: true)
        defer { page.stop() }
        let view = try #require(page.webView)
        view.frame = CGRect(x: 0, y: 0, width: 400, height: 300)
        let window = NSWindow(contentRect: view.frame, styleMask: [.borderless], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.contentView = view
        defer { window.close() }
        // A muted video (it may play without a click) in a frame of another origin, playing a short sound file it writes.
        let inner = """
            <div id="who" data-who="inner"></div><video id="v" muted playsinline></video><script>
            const n = 8000, b = new ArrayBuffer(44 + n * 2), d = new DataView(b);
            const s = (o, t) => { for (let i = 0; i < t.length; i++) d.setUint8(o + i, t.charCodeAt(i)); };
            s(0, 'RIFF'); d.setUint32(4, 36 + n * 2, true); s(8, 'WAVE'); s(12, 'fmt '); d.setUint32(16, 16, true);
            d.setUint16(20, 1, true); d.setUint16(22, 1, true); d.setUint32(24, 8000, true); d.setUint32(28, 16000, true);
            d.setUint16(32, 2, true); d.setUint16(34, 16, true); s(36, 'data'); d.setUint32(40, n * 2, true);
            const v = document.getElementById('v'); v.loop = true;
            v.src = URL.createObjectURL(new Blob([b], { type: 'audio/wav' })); v.play();
            </script>
            """
        let server = try EchoServer(pages: ["/inner": inner])
        view.loadHTMLString(
            "<body data-who='top'><iframe src='http://127.0.0.1:\(server.port)/inner' width=300 height=200></iframe></body>",
            baseURL: URL(string: "http://top.example/")
        )
        // Not observed (`videoFrame` is not shown): polled.
        try await waitUntil(timeout: .seconds(20), label: "the frame's video played") { page.videoFrame != nil }
        let frame = try #require(page.videoFrame)
        #expect(!frame.isMainFrame)
        let who =
            try await view.callAsyncJavaScript(
                "return document.getElementById('who')?.dataset.who + ' ' + document.querySelectorAll('video').length",
                in: frame,
                contentWorld: .defaultClient
            ) as? String
        #expect(who == "inner 1", "Sunset's script runs where the video is")
    }
}
