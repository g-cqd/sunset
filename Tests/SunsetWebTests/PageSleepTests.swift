import AppKit
import Foundation
import SunsetPane
import Testing
import WebKit

@testable import SunsetWeb

/// Roadmap 0021 S-f (R4; ADR-0071): pages not on screen are unloaded after `web.unloadAfter` hours, and under memory
/// pressure the longest idle first; never one that plays, captures, is kept awake or is in the Pinned grid.
@MainActor @Suite("Pages put to sleep", .timeLimit(.minutes(1)))
struct PageSleepTests {
    private let settings = WebSettings(applicationName: "Version/26.0 Safari/605.1.15")

    @Test func `pages hidden longer than the delay go; under pressure the longest idle goes first; exempt ones never`()
    {
        let now = Date(timeIntervalSinceReferenceDate: 1_000_000)
        func hidden(_ hours: Double, exempt: Bool = false) -> PageSleep.Candidate {
            PageSleep.Candidate(hiddenSince: now.addingTimeInterval(-hours * 3600), exempt: exempt)
        }
        let pages = [
            hidden(13), hidden(2), hidden(30, exempt: true), PageSleep.Candidate(hiddenSince: nil, exempt: false)
        ]
        #expect(PageSleep.choose(pages, now: now, unloadAfter: 12, pressure: false) == [0])
        #expect(PageSleep.choose(pages, now: now, unloadAfter: 0, pressure: false).isEmpty, "0: never by the delay")
        #expect(
            PageSleep.choose(pages, now: now, unloadAfter: 0, pressure: true) == [0],
            "the longest idle, one at a time"
        )
        #expect(PageSleep.choose([hidden(1), hidden(5)], now: now, unloadAfter: 12, pressure: true) == [1])
        #expect(
            PageSleep.choose([hidden(1)], now: now, unloadAfter: 12, pressure: true, unloadsUnderPressure: false)
                .isEmpty
        )
    }

    @Test func `a page unloaded lets its view go, keeps its address and history, and comes back when shown`()
        async throws
    {
        let page = WebContent(url: nil, settings: settings)
        page.setState(focused: true, visible: true)
        let view = try #require(page.webView)
        let window = NSWindow(
            contentRect: CGRect(x: 0, y: 0, width: 320, height: 200),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.isReleasedWhenClosed = false
        window.contentView = view
        view.loadHTMLString("<title>Kept</title><body>kept</body>", baseURL: URL(string: "https://example.org/a"))
        await Waiting.until { page.title == "Kept" }
        page.setState(focused: false, visible: false)
        #expect(page.unload())
        #expect(page.webView == nil && page.isUnloaded && page.descriptor.state["history"] != nil)
        #expect(page.title == "Kept", "its row keeps its name")
        page.setState(focused: true, visible: true)
        #expect(page.webView != nil && !page.isUnloaded)
        page.setState(focused: false, visible: true)
        #expect(!page.unload(), "a page on screen is not unloaded")
        window.close()
        page.stop()
    }
}
