import AemiTestKit
import Foundation
import SunsetTestSupport
import Testing
import WebKit

@testable import SunsetWeb
@testable import SunsetWebModel

/// Roadmap 0109 E (the owner: "install directly through their pages"): on a store's page of an extension, "Add to Sunset" by
/// its title, from a script in Sunset's own world; pressed, Sunset is asked to install what the page names: the prompt that
/// follows is the guard (a page's script can press the button too). Not on other pages.
@MainActor @Suite("Add to Sunset on a store's page", .serialized, .timeLimit(.minutes(1)))
struct StoreInstallButtonTests {
    private static let read = "document.querySelector('[data-sunset-install]')?.textContent ?? 'none'"

    private func load(_ address: String) async throws -> (WebContent, WKWebView) {
        let page = WebContent(url: nil, settings: WebSettings(applicationName: "Version/26.0 Safari/605.1.15"))
        page.setState(focused: true, visible: true)
        let view = try #require(page.webView)
        view.loadHTMLString("<main><h1>Dark Reader</h1><p>Text</p></main>", baseURL: URL(string: address))
        try await waitUntil(timeout: .seconds(10), label: "loaded") { !view.isLoading && view.url != nil }
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

    @Test func `on a store's page the button is by the title; pressed, the extension asked to be installed`()
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
