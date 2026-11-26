import AppKit
import Foundation
import Testing
import WebKit

@testable import SunsetWeb
@testable import SunsetWebModel

/// Filling as a page loads (ADR-0094, t103): a sign-in form shown is told once, at load or when the page's script adds
/// it, not a sign-up form's and not in a private page; filled on load, only a form the person has not typed a password
/// in, whose username is empty or the same, and sent to the page's own origin.
@MainActor @Suite("Sign-in forms filled as their page loads", .serialized, .timeLimit(.minutes(1)))
final class PasswordFillOnLoadTests {
    private var windows: [NSWindow] = []
    private var hosts: [PasswordFillTests.Host] = []
    private var pages: [WebContent] = []

    deinit {
        MainActor.assumeIsolated { windows.forEach { $0.close() } }
    }

    static let signIn = """
        <form id="f"><input id="u" autocomplete="username"><input id="p" type="password"></form>
        """
    static let signUp = """
        <form><input id="u" autocomplete="username"><input type="password"><input type="password"></form>
        """
    static let origin = URL(string: "https://example.com")

    private func page(_ html: String, private isPrivate: Bool = false) async throws -> (
        WebContent, WKWebView, PasswordFillTests.Host
    ) {
        var settings = WebSettings(applicationName: "x")
        if isPrivate { settings.privacy = PagePrivacy() }
        let page = WebContent(url: URL(string: "https://example.com/"), settings: settings)
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
        view.loadHTMLString(html, baseURL: URL(string: "https://example.com/signin"))
        await until { !page.isLoading && page.webView?.url != nil }
        return (page, view, host)
    }

    private func run(_ script: String, in view: WKWebView) async throws -> Any? {
        try await view.callAsyncJavaScript(script, contentWorld: .page)
    }

    private func settle(_ view: WKWebView, _ milliseconds: Int = 400) async throws {
        _ = try await run("await new Promise(r => setTimeout(r, \(milliseconds)))", in: view)
    }

    @Test func `a sign-in form is told once as its page loads, or as the page's script shows it`() async throws {
        let (_, view, host) = try await page(Self.signIn)
        await host.wait { !$0.forms.isEmpty }
        let field = try #require(host.forms.first)
        #expect(field.role == .password && field.origin == Self.origin && field.frame.width > 1)
        // Shown again (another form added): still once.
        _ = try await run("document.body.insertAdjacentHTML('beforeend', `\(Self.signIn)`)", in: view)
        try await settle(view)
        #expect(host.forms.count == 1 && host.events.isEmpty)
        // A sign-up form is not one; a sign-in form shown later by the page's script is.
        let (_, later, laterHost) = try await page(Self.signUp + "<div id='box' hidden>\(Self.signIn)</div>")
        try await settle(later)
        #expect(laterHost.forms.isEmpty)
        _ = try await run("document.getElementById('box').hidden = false", in: later)
        await laterHost.wait { !$0.forms.isEmpty }
        #expect(laterHost.forms.count == 1)
    }

    @Test func `a private page tells no form`() async throws {
        let (_, view, host) = try await page(Self.signIn, private: true)
        try await settle(view)
        #expect(host.forms.isEmpty)
    }

    private func fills(_ html: String, typed: [String: String] = [:]) async throws -> (Bool, String) {
        let (page, view, host) = try await page(html)
        await host.wait { !$0.forms.isEmpty }
        for (id, value) in typed {
            _ = try await run("document.getElementById('\(id)').value = '\(value)'", in: view)
        }
        let filled = await page.fillOnLoad(username: "ada", password: "pw1", for: try #require(Self.origin))
        let values = try await run("return ['u', 'p'].map(i => document.getElementById(i).value).join('|')", in: view)
        return (filled, values as? String ?? "")
    }

    @Test func `filled on load only where the person has not typed, and only for the page's own origin`()
        async throws
    {
        #expect(try await fills(Self.signIn) == (true, "ada|pw1"))
        #expect(try await fills(Self.signIn, typed: ["u": "ada"]) == (true, "ada|pw1"))
        #expect(try await fills(Self.signIn, typed: ["u": "bob"]) == (false, "bob|"))
        #expect(try await fills(Self.signIn, typed: ["p": "typed"]) == (false, "|typed"))
        let own = Self.signIn.replacingOccurrences(of: "<form id=\"f\">", with: "<form action=\"/session\">")
        #expect(try await fills(own) == (true, "ada|pw1"))
        for action in ["https://evil.example/collect", "http://example.com/session", "javascript:void(0)"] {
            let elsewhere = Self.signIn.replacingOccurrences(of: "<form id=\"f\">", with: "<form action=\"\(action)\">")
            #expect(try await fills(elsewhere) == (false, "|"), "\(action)")
        }
    }
}
