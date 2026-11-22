import AppKit
import Foundation
import Testing
import WebKit

@testable import SunsetWeb
@testable import SunsetWebModel

/// Filling and saving in pages (roadmap 0094 A, C, D; ADR-0094): a script in Sunset's own world says when a sign-in
/// field takes the keyboard, and where; Sunset fills the form's visible fields on the person's act, as typing would
/// (the page's input events); a password sent is told, with its username, unless the page is private.
@MainActor @Suite("Filling and saving sign-ins", .serialized, .timeLimit(.minutes(1)))
final class PasswordFillTests {
    private var windows: [NSWindow] = []
    private var hosts: [Host] = []
    /// The pages: the script's handler holds its page weakly, as the app's panes hold theirs.
    private var pages: [WebContent] = []

    deinit {
        MainActor.assumeIsolated { windows.forEach { $0.close() } }
    }

    static let page = """
        <form id="f" action="javascript:void 0">
          <input id="u" name="login" type="email" autocomplete="username">
          <input id="trap" type="password" style="display:none">
          <input id="p" type="password" autocomplete="current-password">
          <button id="go" type="submit">Sign In</button>
        </form>
        <input id="search" type="search">
        <script>window.inputs = 0; document.addEventListener('input', () => window.inputs++, true);</script>
        """

    /// What the script told, in order. Kept by the test: `PasswordFill.host` holds it weakly.
    final class Host: PasswordFillHost {
        /// Its page: what other pages tell (tests of other suites, at the same time) is not its.
        weak var page: WebContent?
        var events: [String] = []
        var focused: LoginField?
        var sent: SentLogin?
        private var waiting: CheckedContinuation<Void, Never>?

        func loginField(focused field: LoginField, in page: WebContent) {
            guard page === self.page else { return }
            focused = field
            record("focus \(field.role)")
        }

        func loginFieldBlurred(in page: WebContent) {
            guard page === self.page else { return }
            record("blur")
        }

        func loginSent(_ login: SentLogin, in page: WebContent) {
            guard page === self.page else { return }
            sent = login
            record("sent")
        }

        private func record(_ event: String) {
            events.append(event)
            waiting?.resume()
            waiting = nil
        }

        /// Until `count` events have been told.
        func wait(for count: Int) async {
            await wait { $0.events.count >= count }
        }

        /// Until `done` holds of what was told.
        func wait(until done: (Host) -> Bool) async {
            while !done(self) {
                await withCheckedContinuation { waiting = $0 }
            }
        }
    }

    private func page(private isPrivate: Bool = false) async throws -> (WebContent, WKWebView, Host) {
        var settings = WebSettings(applicationName: "x")
        if isPrivate { settings.privacy = PagePrivacy() }
        let page = WebContent(url: URL(string: "https://example.com/"), settings: settings)
        let host = Host()
        host.page = page
        hosts.append(host)
        pages.append(page)
        page.passwordFillHost = host
        page.setState(focused: true, visible: true)
        let view = try #require(page.webView)
        view.frame = CGRect(x: 0, y: 0, width: 600, height: 400)
        let window = NSWindow(contentRect: view.frame, styleMask: [.borderless], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.contentView = view
        windows.append(window)
        view.loadHTMLString(Self.page, baseURL: URL(string: "https://example.com/signin"))
        await until { !page.isLoading && page.webView?.url != nil }
        _ = try await view.callAsyncJavaScript("await new Promise(r => setTimeout(r, 50))", contentWorld: .page)
        return (page, view, host)
    }

    private func focus(_ id: String, in view: WKWebView) async throws {
        _ = try await view.callAsyncJavaScript(
            "document.getElementById(id).focus()",
            arguments: ["id": id],
            contentWorld: .page
        )
    }

    /// Fills the form, then presses Return in its password field as the person would: a key from AppKit, which the page
    /// sees as real (what a script makes up is not believed).
    private func signIn(in view: WKWebView) async throws {
        _ = try await view.callAsyncJavaScript(
            "document.getElementById('u').value = 'ada'; document.getElementById('p').value = 'pw1'; document.getElementById('p').focus()",
            contentWorld: .page
        )
        let returnKey = try #require(
            NSEvent.keyEvent(
                with: .keyDown,
                location: .zero,
                modifierFlags: [],
                timestamp: 0,
                windowNumber: view.window?.windowNumber ?? 0,
                context: nil,
                characters: "\r",
                charactersIgnoringModifiers: "\r",
                isARepeat: false,
                keyCode: 36
            )
        )
        view.keyDown(with: returnKey)
    }

    private func value(_ id: String, in view: WKWebView) async throws -> String {
        try await view.callAsyncJavaScript(
            "return document.getElementById(id).value",
            arguments: ["id": id],
            contentWorld: .page
        ) as? String ?? ""
    }

    @Test func `a sign-in field's focus is told with its place; another field's is not`() async throws {
        let (_, view, host) = try await page()
        // A window in the background has no focus to give: the focus is told as the browser tells it.
        try await focus("u", in: view)
        await host.wait { $0.focused != nil }
        let field = try #require(host.focused)
        #expect(field.role == .username && field.frame.width > 0 && field.frame.height > 0)
        #expect(field.origin == URL(string: "https://example.com"))
        try await focus("search", in: view)
        await host.wait(for: 2)
        #expect(host.events == ["focus username", "blur"], "the search field says nothing")
    }

    @Test func `filled as typing: the visible username and password, the page's input events; never the hidden field`()
        async throws
    {
        let (page, view, _) = try await page()
        let filled = await page.fill(
            username: "ada@example.com",
            password: "s3cret",
            for: try #require(URL(string: "https://example.com"))
        )
        #expect(filled)
        let (user, password) = (try await value("u", in: view), try await value("p", in: view))
        #expect(user == "ada@example.com" && password == "s3cret")
        #expect(try await value("trap", in: view).isEmpty, "a hidden field is never filled")
        let inputs = try await view.callAsyncJavaScript("return window.inputs", contentWorld: .page) as? Int
        #expect(inputs == 2)
        let seen =
            try await view.callAsyncJavaScript("return typeof window.__sunsetFill", contentWorld: .page) as? String
        #expect(seen == "undefined", "nothing of Sunset's in the page's world")
    }

    @Test func `a password sent is told with its username; in a private window never`() async throws {
        let (_, view, host) = try await page()
        try await signIn(in: view)
        await host.wait { $0.sent != nil }
        let origin = try #require(URL(string: "https://example.com"))
        let sent = try #require(host.sent)
        #expect(sent.origin == origin && sent.username == "ada" && sent.password == "pw1" && sent.frame.width > 0)
        let (_, privateView, privateHost) = try await page(private: true)
        try await signIn(in: privateView)
        _ = try await privateView.callAsyncJavaScript("await new Promise(r => setTimeout(r, 200))", contentWorld: .page)
        #expect(privateHost.sent == nil)
    }

    @Test func `what the page makes up is not believed: a focus or a submit it dispatches tells nothing`() async throws
    {
        let (_, view, host) = try await page()
        _ = try await view.callAsyncJavaScript(
            """
            document.getElementById('p').dispatchEvent(new FocusEvent('focusin', { bubbles: true }));
            document.getElementById('u').value = 'ada'; document.getElementById('p').value = 'forged';
            document.getElementById('f').dispatchEvent(new Event('submit', { bubbles: true }));
            document.getElementById('go').dispatchEvent(new MouseEvent('click', { bubbles: true }));
            """,
            contentWorld: .page
        )
        // A real focus afterwards is told: the made-up ones came first and were not (the browser's own focus of the
        // first field when the page loads is real, and told).
        try await focus("p", in: view)
        await host.wait { $0.events.contains("focus password") }
        #expect(host.events.filter { $0 == "focus password" }.count == 1 && host.sent == nil)
    }

    @Test func `never filled into another origin than the one offered: a page gone elsewhere meanwhile gets nothing`()
        async throws
    {
        let (page, view, _) = try await page()
        let elsewhere = try #require(URL(string: "https://evil.example.net"))
        #expect(await page.fill(username: "ada", password: "s3cret", for: elsewhere) == false)
        #expect(await page.fillNewPassword("s3cret", for: elsewhere) == false)
        #expect(await page.fillCode("123456", for: elsewhere) == false)
        #expect(try await value("p", in: view).isEmpty)
    }

    @Test func `a page that goes away while its field had the keyboard says so: its suggestions close`() async throws {
        let (_, view, host) = try await page()
        try await focus("p", in: view)
        await host.wait { $0.events.contains("focus password") }
        view.loadHTMLString("<p>elsewhere</p>", baseURL: URL(string: "https://example.com/next"))
        await host.wait { $0.events.last == "blur" }
        #expect(host.events.last == "blur")
    }
}
