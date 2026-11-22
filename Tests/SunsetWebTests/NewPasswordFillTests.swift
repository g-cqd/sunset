import AppKit
import Foundation
import Testing
import WebKit

@testable import SunsetWeb
@testable import SunsetWebModel

/// A sign-up form (roadmap 0094 E): its password field is told as a new password, with the page's `passwordrules`; a
/// form of two password fields is one even without the token; filled, the password goes into both, nothing else.
@MainActor @Suite("New passwords into sign-up forms", .serialized, .timeLimit(.minutes(1)))
final class NewPasswordFillTests {
    private var windows: [NSWindow] = []
    private var hosts: [PasswordFillTests.Host] = []
    private var pages: [WebContent] = []

    deinit {
        MainActor.assumeIsolated { windows.forEach { $0.close() } }
    }

    static let page = """
        <form id="tagged"><input id="u1" autocomplete="username">
          <input id="n1" type="password" autocomplete="new-password" passwordrules="minlength: 14; required: digit;"></form>
        <form id="untagged"><input id="u2" type="email">
          <input id="n2" type="password"><input id="c2" type="password"></form>
        """

    private func page() async throws -> (WebContent, WKWebView, PasswordFillTests.Host) {
        let page = WebContent(url: URL(string: "https://example.com/"), settings: WebSettings(applicationName: "x"))
        let host = PasswordFillTests.Host()
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
        view.loadHTMLString(Self.page, baseURL: URL(string: "https://example.com/join"))
        await until { !page.isLoading && page.webView?.url != nil }
        return (page, view, host)
    }

    private func focus(_ id: String, in view: WKWebView) async throws {
        _ = try await view.callAsyncJavaScript(
            "document.getElementById(id).dispatchEvent(new FocusEvent('focusin', { bubbles: true }))",
            arguments: ["id": id],
            contentWorld: .page
        )
    }

    private func value(_ id: String, in view: WKWebView) async throws -> String {
        try await view.callAsyncJavaScript(
            "return document.getElementById(id).value",
            arguments: ["id": id],
            contentWorld: .page
        ) as? String ?? ""
    }

    @Test func `told as new passwords, with the page's rules; two password fields make one without the token`()
        async throws
    {
        let (_, view, host) = try await page()
        try await focus("n1", in: view)
        await host.wait(for: 1)
        #expect(host.focused?.role == .newPassword && host.focused?.rules == "minlength: 14; required: digit;")
        try await focus("n2", in: view)
        await host.wait(for: 2)
        #expect(host.focused?.role == .newPassword && host.focused?.rules == nil)
    }

    @Test func `filled into the password and its confirmation, not the username`() async throws {
        let (page, view, _) = try await page()
        _ = try await view.callAsyncJavaScript("document.getElementById('n2').focus()", contentWorld: .page)
        let filled = await page.fillNewPassword("Fresh-Pa55word")
        #expect(filled)
        let (new, confirmation, user) = (
            try await value("n2", in: view), try await value("c2", in: view), try await value("u2", in: view)
        )
        #expect(new == "Fresh-Pa55word" && confirmation == "Fresh-Pa55word" && user.isEmpty)
        #expect(try await value("n1", in: view).isEmpty, "another form's field is not filled")
    }
}
