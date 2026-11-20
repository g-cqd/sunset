import AemiTestKit
import AppKit
import Foundation
import Testing
import WebKit

@testable import SunsetWeb
@testable import SunsetWebModel

/// Task t97 (diary 2026-11-19-04): what Sunset puts in a page reads as Safari's own. Measured against a driven Safari
/// (the web tester's inventory) and a bare WKWebView: no global of Sunset's, `Notification` shaped as WebKit's, Sunset's
/// functions written `[native code]`, no Private Click Measurement attributes on links (Safari has them off).
@MainActor
@Suite("What a page can tell of Sunset")
struct PageFootprintTests {
    /// WebKit's own `Notification`, read in a bare WKWebView (2026-11-19).
    static let safariPrototype = [
        "body", "close", "constructor", "data", "dir", "icon", "lang", "navigate", "onclick", "onclose", "ondisplay",
        "onerror", "onshow", "show", "silent", "tag", "title"
    ]

    private func page() async throws -> (WebContent, WKWebView) {
        let page = WebContent(url: nil, settings: Self.settings)
        page.permissions.set(.allow, .notifications, for: "chat.example")
        page.setState(focused: false, visible: true)
        let view = try #require(page.webView)
        view.loadHTMLString("<p>chat</p>", baseURL: URL(string: "https://chat.example/"))
        try await waitForObservedState { !page.isLoading && page.webView?.url?.host() == "chat.example" }
        return (page, view)
    }

    private func read(_ view: WKWebView, _ script: String) async throws -> Any? {
        try await view.callAsyncJavaScript(script, contentWorld: .page)
    }

    @Test(.timeLimit(.minutes(1)))
    func `no global of Sunset's, and its functions read as native`() async throws {
        let (page, view) = try await page()
        let globals = try await read(view, "return Object.getOwnPropertyNames(window).filter(n => /sunset/i.test(n))")
        #expect(globals as? [String] == [])
        let texts = try await read(
            view,
            """
            const text = (f) => Function.prototype.toString.call(f);
            return [Notification, Notification.requestPermission, navigator.mediaDevices.getDisplayMedia,
                    Permissions.prototype.query, ServiceWorkerRegistration.prototype.showNotification,
                    Function.prototype.toString]
              .filter(f => !/^function [^(]*\\(\\) \\{\\n    \\[native code\\]\\n\\}$/.test(text(f))).map(text);
            """
        )
        #expect(texts as? [String] == [])
        let pcm = try await read(
            view,
            "return ['attributionDestination', 'attributionSourceId'].filter(k => k in HTMLAnchorElement.prototype)"
        )
        #expect(pcm as? [String] == [])
        page.stop()
    }

    @Test(.timeLimit(.minutes(1)))
    func `Notification is shaped as WebKit's: prototype getters, no fields, no maxActions or __fire`() async throws {
        let (page, view) = try await page()
        let shape = try await read(
            view,
            """
            await Notification.requestPermission();
            const note = new Notification("c", { body: 3, dir: "rtl", actions: [1], renotify: true, requireInteraction: true });
            const thrown = (f) => { try { f(); return "none"; } catch (e) { return e.constructor.name + ": " + e.message; } };
            const title = Object.getOwnPropertyDescriptor(Notification.prototype, "title");
            return {
              proto: Object.getOwnPropertyNames(Notification.prototype).sort(),
              statics: Object.getOwnPropertyNames(Notification).sort(),
              own: Object.getOwnPropertyNames(note),
              values: [note.title, note.body, note.dir, String(note.requireInteraction), String(note.silent)],
              getter: [typeof title.get, String(title.set), title.get.name, String(title.enumerable)],
              call: thrown(() => Notification("x")),
              none: thrown(() => new Notification()),
              dir: thrown(() => new Notification("x", { dir: "up" })),
              other: thrown(() => Notification.prototype.close.call({})),
              length: Notification.length,
              tag: Object.prototype.toString.call(note),
            };
            """
        )
        let found = try #require(shape as? [String: Any])
        #expect(found["proto"] as? [String] == Self.safariPrototype)
        #expect(found["statics"] as? [String] == ["length", "name", "permission", "prototype", "requestPermission"])
        #expect(found["own"] as? [String] == [])
        #expect(found["values"] as? [String] == ["c", "3", "rtl", "undefined", "null"])
        #expect(found["getter"] as? [String] == ["function", "undefined", "get title", "true"])
        #expect(found["call"] as? String == "TypeError: Constructor requires 'new' operator")
        #expect(found["none"] as? String == "TypeError: Not enough arguments")
        #expect(found["dir"] as? String == "TypeError: Type error")
        #expect(found["other"] as? String == "TypeError: Can only call Notification.close on instances of Notification")
        #expect(found["length"] as? Int == 1)
        #expect(found["tag"] as? String == "[object Notification]")
        page.stop()
    }

    /// As the app's pages: `navigator.mediaDevices` there whatever this run's own answers are.
    private static var settings: WebSettings {
        var settings = WebSettings(applicationName: "Version/26.0 Safari/605.1.15")
        settings.mediaDevices = true
        return settings
    }
}
