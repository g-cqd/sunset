import Foundation
import Testing
import WebKit

@testable import SunsetWeb
@testable import SunsetWebModel

/// Task t98: what Safari gives pages and WebKit's views keep off (the inventory against a driven Safari, diary 2026-11-19-04):
/// `requestIdleCallback` (IdleDeadline), and the media session's coordinator and playlist. Each is WebKit's own, turned on;
/// `requestIdleCallback` is checked to work, not only to be there.
@MainActor @Suite("What Safari gives pages", .timeLimit(.minutes(1)))
struct SafariParityTests {
    @Test func `requestIdleCallback runs its callback with a deadline; the media session has Safari's members`()
        async throws
    {
        let page = WebContent(url: nil, settings: WebSettings(applicationName: "Version/26.0 Safari/605.1.15"))
        page.setState(focused: false, visible: true)
        let view = try #require(page.webView)
        view.loadHTMLString("<p>idle</p>", baseURL: URL(string: "https://idle.example/"))
        await Waiting.until { !page.isLoading && page.webView?.url?.host() == "idle.example" }
        let found = try await view.callAsyncJavaScript(
            """
            const has = ["IdleDeadline", "MediaSessionCoordinator"].filter(name => name in window);
            const session = ["coordinator", "playlist"].filter(name => name in MediaSession.prototype);
            if (typeof requestIdleCallback !== "function") return { has, session, ran: "no requestIdleCallback" };
            const ran = await new Promise(done => requestIdleCallback(
              deadline => done(deadline instanceof IdleDeadline && typeof deadline.timeRemaining() === "number" ? "ran" : "odd"),
              { timeout: 2000 }));
            return { has, session, ran };
            """,
            contentWorld: .page
        )
        let result = try #require(found as? [String: Any])
        #expect(result["has"] as? [String] == ["IdleDeadline", "MediaSessionCoordinator"])
        #expect(result["session"] as? [String] == ["coordinator", "playlist"])
        #expect(result["ran"] as? String == "ran")
        page.stop()
    }
}
