import AppKit
import Foundation
import Observation
import Testing
import WebKit

@testable import SunsetWeb

/// Roadmap 0037 C: what the standard asks of `new Notification` beyond the text (notifications.spec.whatwg.org, read
/// 2026-11-17): `actions` are for a service worker's notifications only, and the constructor throws a TypeError for them;
/// `renotify` without a tag throws too; `silent` is the page's to ask, and is handed on.
@MainActor
@Suite("A page's notifications: what the standard asks")
struct WebNotificationsStandardTests {
    @Test(.timeLimit(.minutes(1)))
    func `actions and renotify without a tag throw; silent and requireInteraction are read back, silent handed on`()
        async throws
    {
        var settings = WebSettings(applicationName: "Version/26.0 Safari/605.1.15")
        settings.privacy = PagePrivacy()
        let page = WebContent(url: nil, settings: settings)
        page.permissions.set(.allow, .notifications, for: "chat.example")
        var shown: [WebNotification] = []
        page.onNotify = { shown.append($0) }
        page.setState(focused: false, visible: true)
        let view = try #require(page.webView)
        view.loadHTMLString("<p>chat</p>", baseURL: URL(string: "https://chat.example/"))
        await Waiting.until { !page.isLoading && page.webView?.url?.host() == "chat.example" }
        let result = try await view.callAsyncJavaScript(
            """
            await Notification.requestPermission();
            const thrown = (f) => { try { f(); return "none"; } catch (e) { return e.name; } };
            const actions = thrown(() => new Notification("a", { actions: [{ action: "x", title: "X" }] }));
            const renotify = thrown(() => new Notification("b", { renotify: true }));
            const note = new Notification("c", { silent: true, requireInteraction: true, tag: "t", renotify: true });
            await new Promise(done => { note.onshow = done; note.onerror = done; });
            return [actions, renotify, String(note.silent), String(note.requireInteraction), String(note.renotify)];
            """,
            contentWorld: .page
        )
        #expect(result as? [String] == ["TypeError", "TypeError", "true", "true", "true"])
        #expect(shown.map(\.title) == ["c"] && shown.first?.silent == true)
        page.stop()
    }
}
