import Foundation
import Testing

@testable import SunsetWeb

/// Roadmap 0046 S2 (the owner, 2026-11-18: "this could also be a setting"): a page's `registration.showNotification(…)`, the
/// form sites with a service worker use, is posted as its other notifications are, unless set off.
@MainActor @Suite("A page's notifications through its service worker's registration")
struct WebWorkerNotificationsTests {
    private func page(workers: Bool) -> WebContent {
        var settings = WebSettings(applicationName: "Version/26.0 Safari/605.1.15")
        settings.privacy = PagePrivacy()
        settings.workerNotifications = workers
        let page = WebContent(url: URL(string: "https://chat.example"), settings: settings)
        page.permissions.set(.allow, .notifications, for: "chat.example")
        return page
    }

    @Test func `posted when on, as the page's own; refused when off; the page's own unaffected`() async {
        for workers in [true, false] {
            let page = page(workers: workers)
            var shown: [WebNotification] = []
            page.onNotify = { shown.append($0) }
            let worker: [String: Any] = ["id": 1, "title": "a", "worker": true]
            let posted = await page.notificationAsked("show", worker, host: "chat.example", mainFrame: true, at: 0)
            #expect(posted as? Bool == workers && shown.count == (workers ? 1 : 0))
            let own = await page.notificationAsked(
                "show",
                ["id": 2, "title": "b"],
                host: "chat.example",
                mainFrame: true,
                at: 5
            )
            #expect(own as? Bool == true)
        }
    }

    @Test func `the page's script routes the registration's showNotification to Sunset`() {
        #expect(WebNotifications.script.contains("ServiceWorkerRegistration.prototype"))
        #expect(WebNotifications.script.contains("worker: true"))
    }
}
