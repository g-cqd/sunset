import AppKit
import Foundation
import Observation
import Testing
import WebKit

@testable import SunsetWeb
@testable import SunsetWebModel

/// 0035's "not done": a notification's `tag` (a later one with the same tag replaces it), its `close()` (it is taken
/// away), its `icon` (shown, from an http, https or data address only).
@MainActor
@Suite("A page's notifications: tag, close, icon")
struct WebNotificationsMoreTests {
    private func page() -> WebContent {
        var settings = WebSettings(applicationName: "Version/26.0 Safari/605.1.15")
        settings.privacy = PagePrivacy()
        let page = WebContent(url: URL(string: "https://chat.example"), settings: settings)
        page.permissions.set(.allow, .notifications, for: "chat.example")
        return page
    }

    @Test func `the tag and the icon are handed on; an icon that is not on the web is not`() async {
        let page = page()
        var shown: [WebNotification] = []
        page.onNotify = { shown.append($0) }
        let fields: [String: Any] = ["id": 1, "title": "a", "tag": "room-1", "icon": "https://chat.example/i.png"]
        _ = await page.notificationAsked("show", fields, host: "chat.example", mainFrame: true, at: 0)
        #expect(shown.last?.tag == "room-1" && shown.last?.icon == URL(string: "https://chat.example/i.png"))
        for (index, icon) in ["file:///etc/passwd", "javascript:alert(1)", "data:image/png;base64,AAAA"].enumerated() {
            _ = await page.notificationAsked(
                "show",
                ["id": 2 + index, "title": "b", "icon": icon],
                host: "chat.example",
                mainFrame: true,
                at: Double(10 * (index + 1))
            )
        }
        #expect(shown.dropFirst().map { $0.icon?.scheme } == [nil, nil, "data"])
    }

    @Test func `close takes it away, asked by the page itself only`() async {
        let page = page()
        var closed: [Int] = []
        page.onNotificationClose = { closed.append($0) }
        _ = await page.notificationAsked("close", ["id": 4], host: "chat.example", mainFrame: true, at: 0)
        _ = await page.notificationAsked("close", ["id": 5], host: "chat.example", mainFrame: false, at: 0)
        #expect(closed == [4])
    }
}
