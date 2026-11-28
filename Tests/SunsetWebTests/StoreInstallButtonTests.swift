import AemiTestKit
import Foundation
import SunsetTestSupport
import Testing
import WebKit

@testable import SunsetWeb
@testable import SunsetWebModel

/// On a store's page of an extension, "Add to Sunset" by its title, from a script in Sunset's own world; pressed, Sunset is
/// asked to install what the page names: the prompt that follows is the guard (a page's script can press the button too).
/// Not on other pages.
@MainActor @Suite("Add to Sunset on a store's page", .serialized, .timeLimit(.minutes(1)))
struct StoreInstallButtonTests {
    private static let read = "document.querySelector('[data-sunset-install]')?.textContent ?? 'none'"

    private func load(
        _ address: String,
        html: String = "<main><h1>Dark Reader</h1><p>Text</p></main>"
    ) async throws -> (WebContent, WKWebView) {
        let page = WebContent(url: nil, settings: WebSettings(applicationName: "Version/26.0 Safari/605.1.15"))
        page.setState(focused: true, visible: true)
        let view = try #require(page.webView)
        view.loadHTMLString(html, baseURL: URL(string: address))
        // A loaded CI runner takes over 10 seconds for a first page (seen 2026-11-28); a fast one returns at once.
        try await waitUntil(timeout: .seconds(30), label: "loaded") { !view.isLoading && view.url != nil }
        return (page, view)
    }

    /// The button's text, once there; "none" after two seconds without it.
    private func button(in view: WKWebView) async throws -> String {
        for _ in 0 ..< 20 {
            if let text = try await view.evaluateJavaScript(Self.read) as? String, text != "none" { return text }
            await RealWait.pass(.milliseconds(100))
        }
        return "none"
    }

    @Test(.macOS27) func `on a store's page the button is by the title; pressed, the extension asked to be installed`()
        async throws
    {
        var asked: [ExtensionStoreLink] = []
        ExtensionHosts.shared.installFromStore = { link, _ in asked.append(link) }
        defer { ExtensionHosts.shared.installFromStore = { _, _ in } }
        let (page, view) = try await load(
            "https://chromewebstore.google.com/detail/dark-reader/eimadpbcbfnmbkopoojfekhnkhdbieeh"
        )
        defer { page.stop() }
        #expect(try await button(in: view) == "Add to Sunset")
        let after = try await view.evaluateJavaScript(
            "document.querySelector('h1').nextElementSibling?.hasAttribute('data-sunset-install') ?? false"
        )
        #expect(after as? Bool == true, "right after the title")
        _ = try await view.evaluateJavaScript("document.querySelector('[data-sunset-install]').click(); 1")
        try await waitUntil(timeout: .seconds(5), label: "asked") {
            asked == [.chrome(id: "eimadpbcbfnmbkopoojfekhnkhdbieeh")]
        }
    }

    /// "I can't install from the official buttons" (a German page: "Zu Chrome hinzufügen" was not matched). The store's own
    /// button, in any language, is taken: enabled, "Chrome" said "Sunset", its look kept; pressed, Sunset installs.
    @Test(.macOS27) func `the store's own button is taken in any language`() async throws {
        var asked: [ExtensionStoreLink] = []
        ExtensionHosts.shared.installFromStore = { link, _ in asked.append(link) }
        defer { ExtensionHosts.shared.installFromStore = { _, _ in } }
        let (page, view) = try await load(
            "https://chromewebstore.google.com/detail/ublock-origin-lite/ddkjiahejlhfcafbddmgiahcphecmpfh",
            html:
                "<main><h1>uBlock Origin Lite</h1><div id=bar><button disabled class=theirs><span>Zu Chrome hinzufügen</span></button></div></main>"
        )
        defer { page.stop() }
        #expect(try await button(in: view) == "Zu Sunset hinzufügen")
        let state = try await view.evaluateJavaScript(
            "(() => { const b = document.querySelector('#bar button'); return [b.disabled, b.className, document.querySelectorAll('button').length]; })()"
        )
        let values = try #require(state as? [Any])
        #expect(values[0] as? Bool == false && values[1] as? String == "theirs" && values[2] as? Int == 1)
        _ = try await view.evaluateJavaScript("document.querySelector('#bar button').click(); 1")
        try await waitUntil(timeout: .seconds(5), label: "asked") {
            asked == [.chrome(id: "ddkjiahejlhfcafbddmgiahcphecmpfh")]
        }
    }

    /// Firefox Add-ons is shown Firefox (its own "Add to Firefox" is a link to the `.xpi`, which Sunset installs: probed); no
    /// button of Sunset's there.
    @Test func `Firefox Add-ons sees Firefox and keeps its own button`() async throws {
        let page = WebContent(url: nil, settings: WebSettings(applicationName: "Version/26.0 Safari/605.1.15"))
        defer { page.stop() }
        let firefox = try #require(URL(string: "https://addons.mozilla.org/de/firefox/addon/ublock-origin/"))
        #expect(page.agent(for: firefox) == .firefox)
        let (other, view) = try await load(
            "https://addons.mozilla.org/de/firefox/addon/ublock-origin/",
            html: "<main><h1>uBlock Origin</h1><a href='/x.xpi'>Zu Firefox hinzufügen</a></main>"
        )
        defer { other.stop() }
        #expect(try await button(in: view) == "none")
    }

    /// The store changes its address without loading (seen 2026-11-20: Sunset's button under a search's results).
    @Test func `gone when the store goes to another page without loading`() async throws {
        let (page, view) = try await load(
            "https://chromewebstore.google.com/detail/dark-reader/eimadpbcbfnmbkopoojfekhnkhdbieeh"
        )
        defer { page.stop() }
        #expect(try await button(in: view) == "Add to Sunset")
        _ = try await view.evaluateJavaScript(
            "history.pushState({}, '', '/search/x'); document.querySelector('h1').textContent = 'No search results'; 1"
        )
        await RealWait.pass(.milliseconds(300))
        #expect(try await view.evaluateJavaScript(Self.read) as? String == "none")
    }

    @Test func `not on another page`() async throws {
        let (page, view) = try await load("https://example.com/detail/dark-reader/eimadpbcbfnmbkopoojfekhnkhdbieeh")
        defer { page.stop() }
        #expect(try await button(in: view) == "none")
    }

    /// A `.crx` a page opens (a link, a store's "Download file"): handed to the install, not downloaded.
    @Test func `a package a page opens goes to the install, not to Downloads`() async throws {
        var asked: [URL] = []
        ExtensionHosts.shared.installPackage = { address, _ in asked.append(address) }
        defer { ExtensionHosts.shared.installPackage = { _, _ in } }
        let server = try EchoServer(files: ["/x.crx": ("application/x-chrome-extension", Data("Cr24".utf8))])
        let page = WebContent(
            url: URL(string: "http://127.0.0.1:\(server.port)/x.crx"),
            settings: WebSettings(applicationName: "Version/26.0 Safari/605.1.15")
        )
        page.setState(focused: true, visible: true)
        defer { page.stop() }
        try await waitUntil(timeout: .seconds(10), label: "handed to the install") { asked.map(\.path) == ["/x.crx"] }
        #expect(!DownloadCenter.shared.items.contains { $0.source?.path == "/x.crx" })
    }
}
