import AemiTestKit
import Foundation
import Testing
import WebKit

@testable import SunsetWeb
@testable import SunsetWebModel

/// Task t97: the person's click on a page's notification reaches the page by its pull through Sunset's handler, never an
/// event on its window any script could fire (white paper §9: a page cannot make its own notifications look clicked).
@MainActor
@Suite("A page's notifications: the person's clicks")
struct NotificationClicksTests {
    @Test func `clicks made while no pull waits are kept in order, a few at most; none after the page ends`() async {
        let clicks = NotificationClicks()
        for id in 1 ... (NotificationClicks.most + 4) { clicks.clicked(id) }
        #expect(await clicks.next() == 1)
        #expect(await clicks.next() == 2)
        clicks.end()
        clicks.clicked(99)
        #expect(await clicks.next() == 99)
    }

    @Test(.timeLimit(.minutes(1)))
    func `the click reaches its notification's onclick and listeners once, and a page's own events do nothing`()
        async throws
    {
        let page = WebContent(url: nil, settings: WebSettings(applicationName: "Version/26.0 Safari/605.1.15"))
        page.permissions.set(.allow, .notifications, for: "chat.example")
        var shown: [WebNotification] = []
        var notified: (() -> Void)?
        page.onNotify = {
            shown.append($0)
            notified?()
        }
        page.setState(focused: false, visible: true)
        let view = try #require(page.webView)
        view.loadHTMLString("<p>chat</p>", baseURL: URL(string: "https://chat.example/"))
        try await waitForObservedState { !page.isLoading && page.webView?.url?.host() == "chat.example" }
        var heard: Result<Any, any Error>?
        var resume: (() -> Void)?
        view.callAsyncJavaScript(
            """
            await Notification.requestPermission();
            const note = new Notification("call", { body: "ringing" });
            const heard = [];
            note.onclick = () => heard.push("onclick");
            note.addEventListener("click", (e) => heard.push("listener " + e.isTrusted));
            await new Promise(done => { note.onshow = done; note.onerror = done; });
            // What Sunset's script once heard on the window: a page firing it must not look like the person's click.
            dispatchEvent(new CustomEvent("sunset-notification-click", { detail: 1 }));
            window.webkit.messageHandlers.sunsetNotifications.postMessage({ kind: "click", id: 1 });
            const late = new Promise(done => setTimeout(done, 3000));
            await Promise.race([late, new Promise(done => note.addEventListener("click", () => setTimeout(done, 200)))]);
            return heard;
            """,
            in: nil,
            in: .page
        ) {
            heard = $0
            resume?()
        }
        if shown.isEmpty { await withCheckedContinuation { done in notified = { done.resume() } } }
        page.notificationClicked(shown[0].id)
        if heard == nil { await withCheckedContinuation { done in resume = { done.resume() } } }
        // Fired by a script, the event is not trusted (Safari's is): a difference no page script can close.
        #expect(try heard?.get() as? [String] == ["onclick", "listener false"])
        page.stop()
    }
}
