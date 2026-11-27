import AemiTestKit
import CoreGraphics
import Foundation
import SunsetPane
import SunsetRuntime
import Testing
import WebKit

@testable import SunsetWeb
@testable import SunsetWebModel

/// A share's frames reach the page by its pull through Sunset's handler, never a function on its window; only the origin
/// that asked is given any (white paper §9: a frame of another site in the call's page gets no pixel of the share).
@MainActor
@Suite("Share: frames pulled by the asking origin")
struct ShareFramesTests {
    private func session() -> ShareSession {
        let page = WebContent(descriptor: PaneDescriptor(kind: "web", state: [:]), settings: WebSettings())
        let feed = ShareFeed(frame: { nil }, isOpen: { true }, host: { nil })
        return ShareSession(source: UUID(), feed: feed, page: page, asker: "https://call.example:0")
    }

    @Test func `another origin, or none, gets nothing; the asker gets the newest frame, none piled up`() async {
        let share = session()
        share.deliver("one")
        share.deliver("two")
        #expect(await share.pull(from: "https://ads.example:0") == nil)
        #expect(await share.pull(from: nil) == nil)
        #expect(await share.pull(from: "https://call.example:0") == "two")
        share.stop(.stopped)
    }

    @Test func `only the asker ends it: another origin's "ended" is not believed`() async {
        let share = session()
        share.ended(by: "https://ads.example:0")
        share.ended(by: nil)
        share.deliver("still")
        #expect(await share.pull(from: "https://call.example:0") == "still")
        share.ended(by: "https://call.example:0")
        share.deliver("late")
        #expect(await share.pull(from: "https://call.example:0") == nil)
    }

    @Test func `nothing once the share stops`() async {
        let share = session()
        share.deliver("kept")
        share.stop(.stopped)
        #expect(await share.pull(from: "https://call.example:0") == nil)
        share.deliver("late")
        #expect(await share.pull(from: "https://call.example:0") == nil)
    }

    @Test(.timeLimit(.minutes(1)))
    func `a page's track is drawn from Sunset's frames, with nothing of Sunset's on its window`() async throws {
        let image = try #require(Self.red())
        WebShare.pickSystem = { ShareFeed(frame: { image }, isOpen: { true }, host: { "picked" }) }
        defer { WebShare.pickSystem = { nil } }
        let page = WebContent(url: nil, settings: Self.settings)
        page.setState(focused: false, visible: true)
        let view = try #require(page.webView)
        view.loadHTMLString("<p>call</p>", baseURL: URL(string: "https://call.example/"))
        try await waitForObservedState { !page.isLoading && page.webView?.url?.host() == "call.example" }
        var drawn: Result<Any, any Error>?
        var resume: (() -> Void)?
        // The person clicked in the page a moment before: only then is the screen asked for.
        page.lastUserInput = page.runtime.uptime()
        view.callAsyncJavaScript(
            """
            let stage = "asked";
            const late = new Promise((_, no) => setTimeout(() => no(new Error("no frame in 20 s: " + stage)), 20000));
            return await Promise.race([late, (async () => {
            const stream = await navigator.mediaDevices.getDisplayMedia({ video: true });
            stage = "given";
            const [track] = stream.getVideoTracks();
            // The canvas behind the track takes each frame's size (1280×720 before the first): 64×64 is Sunset's frame drawn.
            for (let i = 0; i < 200 && track.getSettings().width !== 64; i++) {
              stage = "size " + track.getSettings().width; await new Promise(r => setTimeout(r, 50));
            }
            const settings = track.getSettings();
            const own = Object.getOwnPropertyNames(track).concat(Object.getOwnPropertyNames(stream));
            const globals = Object.getOwnPropertyNames(window).filter(n => /sunset/i.test(n));
            return { size: settings.width + "x" + settings.height, own, globals };
            })()]);
            """,
            in: nil,
            in: .page
        ) {
            drawn = $0
            resume?()
        }
        try await waitForObservedState { page.shareRequest != nil }
        page.shareRequest?.answer(.system)
        if drawn == nil { await withCheckedContinuation { done in resume = { done.resume() } } }
        let found = try #require(try drawn?.get() as? [String: Any])
        #expect(found["size"] as? String == "64x64")
        #expect(found["own"] as? [String] == [])
        #expect(found["globals"] as? [String] == [])
        #expect(page.share?.asker == "https://call.example:0")
        page.share?.stop(.stopped)
        page.stop()
    }

    private static func red() -> CGImage? {
        let context = CGContext(
            data: nil,
            width: 64,
            height: 64,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )
        context?.setFillColor(red: 1, green: 0, blue: 0, alpha: 1)
        context?.fill(CGRect(x: 0, y: 0, width: 64, height: 64))
        return context?.makeImage()
    }

    /// As the app's pages: `navigator.mediaDevices` there whatever this run's own answers are.
    private static var settings: WebSettings {
        var settings = WebSettings(applicationName: "Version/26.0 Safari/605.1.15")
        settings.mediaDevices = true
        return settings
    }
}
