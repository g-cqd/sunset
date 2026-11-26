import AppKit
import Foundation
import Testing
import WebKit

@testable import SunsetWeb
@testable import SunsetWebModel

/// Contact and address fields (roadmap 0094, t103): one is told as one by its autofill token, its type or its name, but
/// a sign-in form's email stays its username; filled, each value goes in its field (a street on one line or several, a
/// country in a menu by its code or its name), and nothing into a hidden field, a card's or a password.
@MainActor @Suite("Identities into pages", .serialized, .timeLimit(.minutes(1)))
final class IdentityFillTests {
    private var windows: [NSWindow] = []
    private var hosts: [PasswordFillTests.Host] = []
    private var pages: [WebContent] = []

    deinit {
        MainActor.assumeIsolated { windows.forEach { $0.close() } }
    }

    static let page = """
        <form id="one"><input id="g1" autocomplete="given-name"><input id="f1" autocomplete="family-name">
          <input id="e1" autocomplete="email"><input id="t1" autocomplete="tel">
          <textarea id="s1" autocomplete="shipping street-address"></textarea>
          <input id="c1" autocomplete="shipping address-level2"><input id="p1" autocomplete="shipping postal-code">
          <select id="k1" autocomplete="country"><option value="">-</option><option value="FR">France</option>
            <option value="GB">United Kingdom</option></select>
          <input id="hidden1" autocomplete="email" style="display:none"><input id="cc1" autocomplete="cc-number"></form>
        <form id="two"><input id="g2" name="fname"><input id="f2" name="lname"><input id="a2" name="address1">
          <input id="b2" name="address2"><input id="c2" name="city"><input id="r2" name="state"><input id="z2" name="zip">
          <select id="k2" name="country"><option value="">-</option><option value="UK">United Kingdom</option></select>
          <input id="full2" name="street" autocomplete="street-address"></form>
        <form id="login"><input id="user" type="email" name="email"><input id="pass" type="password"></form>
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
        view.frame = CGRect(x: 0, y: 0, width: 800, height: 600)
        let window = NSWindow(contentRect: view.frame, styleMask: [.borderless], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.contentView = view
        windows.append(window)
        view.loadHTMLString(Self.page, baseURL: URL(string: "https://shop.example.com/address"))
        await until { !page.isLoading && page.webView?.url != nil }
        return (page, view, host)
    }

    private func run(_ script: String, in view: WKWebView) async throws -> Any? {
        try await view.callAsyncJavaScript(script, contentWorld: .page)
    }

    private func values(_ ids: [String], in view: WKWebView) async throws -> String? {
        let list = ids.map { "'\($0)'" }.joined(separator: ",")
        return try await run("return [\(list)].map(i => document.getElementById(i).value).join('|')", in: view)
            as? String
    }

    private let identity = [
        "given-name": "Ada", "family-name": "Lovelace", "name": "Ada Lovelace", "email": "ada@example.com",
        "tel": "+44 20 7946 0000", "street-address": "1 Road\nFlat 2", "address-line1": "1 Road",
        "address-line2": "Flat 2", "address-level2": "London", "postal-code": "N1 9GU", "address-level1": "England",
        "country": "GB"
    ]

    @Test func `a contact field is told as one by its token or its name; a sign-in form's email is its username`()
        async throws
    {
        let (_, view, host) = try await page()
        for (id, event) in [("e1", "focus identity"), ("search", "blur"), ("z2", "focus identity")] {
            _ = try await run("document.getElementById('\(id)').focus()", in: view)
            await host.wait { $0.events.last == event }
        }
        _ = try await run("document.getElementById('user').focus()", in: view)
        await host.wait { $0.events.last == "focus username" }
    }

    @Test func `filled field by field, a street on its lines, a country by its code or its name`() async throws {
        let (page, view, _) = try await page()
        let site = try #require(URL(string: "https://shop.example.com"))
        _ = try await run("document.getElementById('g1').focus()", in: view)
        #expect(await page.fillIdentity(identity, for: site))
        let one = try await values(["g1", "f1", "e1", "t1", "s1", "c1", "p1", "k1", "hidden1", "cc1"], in: view)
        #expect(one == "Ada|Lovelace|ada@example.com|+44 20 7946 0000|1 Road\nFlat 2|London|N1 9GU|GB||")
        _ = try await run("document.getElementById('a2').focus()", in: view)
        #expect(await page.fillIdentity(identity, for: site))
        let two = try await values(["g2", "f2", "a2", "b2", "c2", "r2", "z2", "k2", "full2"], in: view)
        #expect(two == "Ada|Lovelace|1 Road|Flat 2|London|England|N1 9GU|UK|1 Road, Flat 2")
        #expect(try await values(["user", "pass"], in: view) == "|", "another form is left as it was")
    }

    @Test func `nothing is filled for another origin, or from a field that is not a contact one`() async throws {
        let (page, view, _) = try await page()
        _ = try await run("document.getElementById('g1').focus()", in: view)
        #expect(await !page.fillIdentity(identity, for: try #require(URL(string: "https://shop.example.net"))))
        _ = try await run("document.getElementById('cc1').focus()", in: view)
        #expect(await !page.fillIdentity(identity, for: try #require(URL(string: "https://shop.example.com"))))
        #expect(try await values(["g1", "cc1"], in: view) == "|")
    }
}
