import AemiTestKit
import Foundation
import Observation
import SunsetTestSupport
import Testing

@testable import SunsetWeb
@testable import SunsetWebModel

/// A page asks for notifications only from what the person did (white paper §9; the review of 2026-11-17): as Safari, a
/// `requestPermission()` without a user gesture is answered by the site's standing answer and asks nobody; and one question at
/// a time per page, a second asked meanwhile answered at once.
@MainActor
@Suite("A page's notification question")
struct WebNotificationsAskTests {
    private func page(withoutClick: Bool = false) -> WebContent {
        var settings = WebSettings(applicationName: "Version/26.0 Safari/605.1.15")
        settings.privacy = PagePrivacy()
        settings.notificationAskWithoutClick = withoutClick
        return WebContent(url: URL(string: "https://chat.example"), settings: settings)
    }

    private func request(_ page: WebContent, activated: Bool) async -> String? {
        await page.notificationAsked("request", ["activated": activated], host: "chat.example", mainFrame: true, at: 0)
            as? String
    }

    @MainActor @Observable
    final class Flag {
        var done = false
    }

    /// Whichever comes first: `work` ends (false), or the page shows a question (true, then refused so that `work` ends).
    private func asks(_ page: WebContent, while work: @escaping @MainActor () async -> Void) async throws -> Bool {
        let flag = Flag()
        let running = Task { @MainActor in
            await work()
            flag.done = true
        }
        try await waitUntil { flag.done || page.permissionRequest != nil }
        let asked = !flag.done
        page.permissionRequest?.choose(.deny, keepIn: SitePermissions(table: nil))
        await running.value
        return asked
    }

    @Test(.timeLimit(.minutes(1)))
    func `without a gesture the page is answered by the site's answer and nobody is asked`() async throws {
        let page = page()
        var answer: String?
        let asked = try await asks(page) { answer = await self.request(page, activated: false) }
        #expect(!asked, "nobody is asked without a gesture")
        #expect(asked || answer == "default")
    }

    @Test(.timeLimit(.minutes(1)))
    func `with a gesture the person is asked once; a second request meanwhile is answered at once`() async throws {
        let page = page()
        let first = Task { await request(page, activated: true) }
        try await waitForObservedState { page.permissionRequest != nil }
        let shown = try #require(page.permissionRequest)
        var second: String?
        let asking = Task { second = await request(page, activated: true) }
        // Answered at once, or else asked again once the first question is answered.
        let started = Task { shown.choose(.allowOnce, keepIn: SitePermissions(table: nil)) }
        await started.value
        let askedAgain = try await asks(page) { await asking.value }
        #expect(!askedAgain, "not queued behind the question shown, nor asked again")
        #expect(await first.value == "granted")
        #expect(askedAgain || second == "default" || second == "granted")
    }

    /// Roadmap 0046 S1 (the owner, 2026-11-18: "this could be a setting"): as Chrome, a request without a click asks.
    @Test(.timeLimit(.minutes(1)))
    func `set to ask without a click, a request without a gesture asks the person`() async throws {
        let page = page(withoutClick: true)
        let asked = try await asks(page) { _ = await self.request(page, activated: false) }
        #expect(asked)
    }
}
