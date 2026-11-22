import AppKit
import Foundation
import Observation
import Testing
import WebKit

@testable import SunsetWeb
@testable import SunsetWebModel

/// "Web notifications don't work with system notifications". A page's `Notification` is Sunset's (a script at the
/// document's start); what it asks reaches the page's content, which answers by the site's standing answer and hands
/// what may be shown to the app (white paper §9: untrusted input has a policy).
@MainActor
@Suite("A page's notifications")
struct WebNotificationsTests {
    /// A private page: its answers are its own, in memory.
    private func page() -> (WebContent, [WebNotification]) {
        var settings = WebSettings(applicationName: "Version/26.0 Safari/605.1.15")
        settings.privacy = PagePrivacy()
        return (WebContent(url: URL(string: "https://chat.example"), settings: settings), [])
    }

    /// What the page is answered when it asks `kind` from the page itself at chat.example.
    private func word(_ page: WebContent, _ kind: String) async -> String? {
        await page.notificationAsked(kind, [:], host: "chat.example", mainFrame: true, at: 0) as? String
    }

    @Test func `the page reads the site's answer as the API words it`() async {
        let (page, _) = page()
        #expect(await word(page, "permission") == "default")
        page.permissions.set(.allow, .notifications, for: "chat.example")
        #expect(await word(page, "permission") == "granted")
        page.permissions.set(.deny, .notifications, for: "chat.example")
        #expect(await word(page, "permission") == "denied")
    }

    @Test
    func `a site allowed has its notification handed to the app, one line each, not longer than a notification shows`()
        async
    {
        let (page, _) = page()
        var shown: [WebNotification] = []
        page.onNotify = { shown.append($0) }
        page.permissions.set(.allow, .notifications, for: "chat.example")
        let long = String(repeating: "a", count: 1000)
        let reply = await page.notificationAsked(
            "show",
            ["id": 7, "title": "New\u{202E}message\n", "body": long],
            host: "chat.example",
            mainFrame: true,
            at: 10
        )
        #expect(reply as? Bool == true)
        #expect(shown.count == 1)
        #expect(shown.first?.id == 7 && shown.first?.host == "chat.example")
        #expect(shown.first?.title == "Newmessage")
        #expect((shown.first?.body.count ?? 0) <= WebNotification.bodyLimit)
    }

    @Test func `nothing is shown for a site not allowed, nor from a frame inside the page`() async {
        let (page, _) = page()
        var shown: [WebNotification] = []
        page.onNotify = { shown.append($0) }
        let fields: [String: Any] = ["id": 1, "title": "Hi", "body": ""]
        #expect(
            await page.notificationAsked("show", fields, host: "chat.example", mainFrame: true, at: 0) as? Bool == false
        )
        page.permissions.set(.allow, .notifications, for: "chat.example")
        #expect(
            await page.notificationAsked("show", fields, host: "chat.example", mainFrame: false, at: 0) as? Bool
                == false
        )
        #expect(await page.notificationAsked("show", fields, host: nil, mainFrame: true, at: 0) as? Bool == false)
        #expect(shown.isEmpty)
    }

    @Test func `a page shows one notification a second at most`() async {
        let (page, _) = page()
        var shown: [WebNotification] = []
        page.onNotify = { shown.append($0) }
        page.permissions.set(.allow, .notifications, for: "chat.example")
        for (index, second) in [100.0, 100.5, 101.2].enumerated() {
            _ = await page.notificationAsked(
                "show",
                ["id": index, "title": "\(index)"],
                host: "chat.example",
                mainFrame: true,
                at: second
            )
        }
        #expect(shown.map(\.id) == [0, 2])
    }

    @Test func `asking a site already answered answers without a question`() async {
        let (page, _) = page()
        page.permissions.set(.allow, .notifications, for: "chat.example")
        #expect(await word(page, "request") == "granted")
        page.permissions.set(.deny, .notifications, for: "chat.example")
        #expect(await word(page, "request") == "denied")
        #expect(page.permissionRequest == nil)
    }

    /// The page once it has loaded `address`: waited for as changes of its state, never on a clock.
    private func loaded(_ page: WebContent, host: String) async {
        while page.isLoading || page.webView?.url?.host() != host {
            await withCheckedContinuation { (done: CheckedContinuation<Void, Never>) in
                withObservationTracking {
                    _ = page.isLoading
                    _ = page.url
                } onChange: {
                    done.resume()
                }
            }
        }
    }

    @Test(.timeLimit(.minutes(1)))
    func `in a real page, Notification is Sunset's: asked, it is granted by the site's answer, and shown`() async throws
    {
        let (page, _) = page()
        var shown: [WebNotification] = []
        page.onNotify = { shown.append($0) }
        var closed: [Int] = []
        page.onNotificationClose = { closed.append($0) }
        page.permissions.set(.allow, .notifications, for: "chat.example")
        page.setState(focused: false, visible: true)
        let view = try #require(page.webView)
        view.loadHTMLString("<p>chat</p>", baseURL: URL(string: "https://chat.example/"))
        await loaded(page, host: "chat.example")
        let result = try await view.callAsyncJavaScript(
            """
            const asked = await Notification.requestPermission();
            const note = new Notification("Hi", { body: "there" });
            const outcome = await new Promise(done => { note.onshow = () => done("show"); note.onerror = () => done("error"); });
            const closed = new Promise(done => { note.onclose = () => done("close"); });
            note.close();
            return [asked, Notification.permission, outcome, await closed];
            """,
            contentWorld: .page
        )
        #expect(result as? [String] == ["granted", "granted", "show", "close"])
        #expect(shown.map(\.title) == ["Hi"] && shown.first?.body == "there" && shown.first?.host == "chat.example")
        #expect(closed == shown.map(\.id), "close() reached Sunset")
        page.stop()
    }
}
