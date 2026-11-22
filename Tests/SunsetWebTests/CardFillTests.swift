import AppKit
import Foundation
import Testing
import WebKit

@testable import SunsetWeb
@testable import SunsetWebModel

/// Cards into pages (roadmap 0094 F): a card's field is told as one (a `cc-` token, or named for a card's number); filled,
/// each value goes where the form wants it, an expiry in one field or in a month and a year (inputs or menus).
@MainActor @Suite("Cards into pages", .serialized, .timeLimit(.minutes(1)))
final class CardFillTests {
    private var windows: [NSWindow] = []
    private var hosts: [PasswordFillTests.Host] = []
    private var pages: [WebContent] = []

    deinit {
        MainActor.assumeIsolated { windows.forEach { $0.close() } }
    }

    static let page = """
        <form id="one"><input id="n1" autocomplete="cc-number"><input id="h1" autocomplete="cc-name">
          <input id="e1" autocomplete="cc-exp" maxlength="5"><input id="c1" autocomplete="cc-csc"></form>
        <form id="two"><input id="n2" name="cardnumber"><input id="h2" name="cardholder">
          <select id="m2" name="exp-month"><option value="">MM</option><option value="1">01</option><option value="4">04</option></select>
          <select id="y2" name="exp-year"><option value="">YYYY</option><option value="2030">2030</option><option value="2031">2031</option></select>
          <input id="c2" name="cvc"></form>
        <input id="search" type="search">
        """

    private func page() async throws -> (WebContent, WKWebView, PasswordFillTests.Host) {
        let page = WebContent(
            url: URL(string: "https://shop.example.com/"),
            settings: WebSettings(applicationName: "x")
        )
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
        view.loadHTMLString(Self.page, baseURL: URL(string: "https://shop.example.com/pay"))
        await until { !page.isLoading && page.webView?.url != nil }
        return (page, view, host)
    }

    private func run(_ script: String, in view: WKWebView) async throws -> Any? {
        try await view.callAsyncJavaScript(script, contentWorld: .page)
    }

    private let card: [String: String] = [
        "number": "4111111111111111", "name": "Ada Lovelace", "month": "04", "year": "2031", "code": "123"
    ]
    private let origin = URL(string: "https://shop.example.com")

    @Test func `a card's field is told as one, by its token or its name`() async throws {
        let (_, view, host) = try await page()
        _ = try await run("document.getElementById('n1').focus()", in: view)
        await host.wait { $0.events.contains("focus card") }
        _ = try await run("document.getElementById('search').focus()", in: view)
        await host.wait { $0.events.last == "blur" }
        _ = try await run("document.getElementById('n2').focus()", in: view)
        await host.wait { $0.events.filter { $0 == "focus card" }.count == 2 }
    }

    @Test func `filled where the form wants each value: one expiry field, or a month and a year in menus`() async throws
    {
        let (page, view, _) = try await page()
        let site = try #require(origin)
        _ = try await run("document.getElementById('n1').focus()", in: view)
        #expect(await page.fillCard(card, for: site))
        let one = try await run(
            "return ['n1','h1','e1','c1'].map(i => document.getElementById(i).value).join('|')",
            in: view
        )
        #expect(one as? String == "4111111111111111|Ada Lovelace|04/31|123")
        _ = try await run("document.getElementById('n2').focus()", in: view)
        #expect(await page.fillCard(card, for: site))
        let two = try await run(
            "return ['n2','h2','m2','y2','c2'].map(i => document.getElementById(i).value).join('|')",
            in: view
        )
        #expect(two as? String == "4111111111111111|Ada Lovelace|4|2031|123")
    }
}
