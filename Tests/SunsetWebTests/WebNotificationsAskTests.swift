import Foundation
import Observation
import Testing

@testable import SunsetWeb

/// A page asks for notifications only from what the person did (white paper §9; the review of 2026-11-17): as Safari, a
/// `requestPermission()` without a user gesture is answered by the site's standing answer and asks nobody; and one question at
/// a time per page, a second asked meanwhile answered at once.
@MainActor
@Suite("A page's notification question")
struct WebNotificationsAskTests {
    private func page() -> WebContent {
        var settings = WebSettings(applicationName: "Version/26.0 Safari/605.1.15")
        settings.privacy = PagePrivacy()
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
    private func asks(_ page: WebContent, while work: @escaping @MainActor () async -> Void) async -> Bool {
        let flag = Flag()
        let running = Task { @MainActor in
            await work()
            flag.done = true
        }
        await Waiting.until { flag.done || page.permissionRequest != nil }
        let asked = !flag.done
        page.permissionRequest?.choose(.deny, keepIn: SitePermissions(table: nil))
        await running.value
        return asked
    }

    @Test(.timeLimit(.minutes(1)))
    func `without a gesture the page is answered by the site's answer and nobody is asked`() async {
        let page = page()
        var answer: String?
        let asked = await asks(page) { answer = await self.request(page, activated: false) }
        #expect(!asked, "nobody is asked without a gesture")
        #expect(asked || answer == "default")
    }

    @Test(.timeLimit(.minutes(1)))
    func `with a gesture the person is asked once; a second request meanwhile is answered at once`() async throws {
        let page = page()
        let first = Task { await request(page, activated: true) }
        await Waiting.until { page.permissionRequest != nil }
        let shown = try #require(page.permissionRequest)
        var second: String?
        let asking = Task { second = await request(page, activated: true) }
        // Answered at once, or else asked again once the first question is answered.
        let started = Task { shown.choose(.allowOnce, keepIn: SitePermissions(table: nil)) }
        await started.value
        let askedAgain = await asks(page) { await asking.value }
        #expect(!askedAgain, "not queued behind the question shown, nor asked again")
        #expect(await first.value == "granted")
        #expect(askedAgain || second == "default" || second == "granted")
    }
}
