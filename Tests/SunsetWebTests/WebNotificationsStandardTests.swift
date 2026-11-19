import AppKit
import Foundation
import Observation
import Testing
import WebKit

@testable import SunsetWeb
@testable import SunsetWebModel

/// Roadmap 0037 C, as WebKit has it (task t97, read in a bare WKWebView 2026-11-19): the standard's TypeErrors for `actions`
/// and for `renotify` without a tag (notifications.spec.whatwg.org) are not WebKit's, which ignores both, and has no
/// `requireInteraction`, `renotify`, `timestamp`; a page tells Sunset from Safari by any difference. `silent` is the page's
/// to ask, and is handed on.
@MainActor
@Suite("A page's notifications: what the standard asks")
struct WebNotificationsStandardTests {
    @Test(.timeLimit(.minutes(1)))
    func `as WebKit's: actions and renotify ignored, silent read back and handed on, no requireInteraction`()
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
            const note = new Notification("c", { silent: true, requireInteraction: true, tag: "t", renotify: true });
            await new Promise(done => { note.onshow = done; note.onerror = done; });
            // Within the second: made, not shown.
            const actions = thrown(() => new Notification("a", { actions: [{ action: "x", title: "X" }] }));
            const renotify = thrown(() => new Notification("b", { renotify: true }));
            return [actions, renotify, String(note.silent), String(note.requireInteraction), String(note.renotify), String(note.timestamp)];
            """,
            contentWorld: .page
        )
        #expect(result as? [String] == ["none", "none", "true", "undefined", "undefined", "undefined"])
        #expect(shown.map(\.title) == ["c"] && shown.first?.silent == true)
        page.stop()
    }
}
