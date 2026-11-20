import AemiTestKit
import AppKit
import Foundation
import SunsetTestSupport
import Testing
import WebKit

@testable import SunsetWeb
@testable import SunsetWebModel

/// Roadmap 0045 F (the owner, 2026-11-18: [a business site] and its siblings "not loading properly as they would in
/// Chrome or Safari"). Such a site sends a browser it does not support to a page of its own with `location.replace`, and
/// that page never sends it back: shown Chrome afterwards and loaded again, the site stayed on its "unsupported" page.
/// What the person asked for is what is loaded again when the site's browser changes.
@MainActor @Suite("A site shown another browser is asked again for what the person asked", .timeLimit(.minutes(1)))
struct AppearAgainTests {
    /// The site's sniffing, as the site's `browser-checker` does it: not Chrome, away for good.
    static let sniffing = """
        <script>if (!/ Chrome\\//.test(navigator.userAgent)) location.replace('/unsupported?skip=true')</script>
        """

    @Test func `the address asked for is kept, and moved from only by the person`() throws {
        var asked = AskedAddress()
        let start = try #require(URL(string: "https://site.example/start"))
        let away = try #require(URL(string: "https://site.example/unsupported"))
        asked.asked(start)
        #expect(asked.target(current: start) == nil, "on what was asked: loaded again as it is")
        asked.navigation(to: start, type: .other)
        #expect(asked.target(current: start) == nil, "Sunset's own load of what was asked")
        asked.navigation(to: away, type: .other)
        #expect(asked.target(current: away) == start, "the site's script sent the page away")
        asked.navigation(to: away, type: .reload)
        #expect(asked.target(current: away) == start, "loading the page it was sent to again asks nothing new")
        asked.navigation(to: away, type: .linkActivated)
        #expect(asked.target(current: away) == nil, "a link the person followed is what they asked")
        let elsewhere = try #require(URL(string: "https://other.example/"))
        asked.asked(start)
        asked.navigation(to: elsewhere, type: .other)
        #expect(asked.target(current: elsewhere) == nil, "sent to another site: that one is loaded again")
    }

    @Test func `a site that sent the page away is loaded at the address asked for once it is shown Chrome`()
        async throws
    {
        let server = try EchoServer(pages: ["/start": Self.sniffing])
        let page = WebContent(url: nil, settings: WebSettings(applicationName: "Version/26.0 Safari/605.1.15"))
        page.agents = SiteAgents()
        page.setState(focused: true, visible: true)
        page.load(try #require(URL(string: "http://127.0.0.1:\(server.port)/start")))
        try await waitForObservedState { page.url?.path() == "/unsupported" && !page.isLoading }
        page.appear(as: .chrome)
        // Loaded again: a request with Chrome's name, then the end of its load (what is observed is read first).
        try await Poll.until { !page.isLoading && server.received.contains { $0.contains("Chrome/") } }
        #expect(page.url?.path() == "/start")
        #expect(server.header("User-Agent", for: "/start") == BrowserAgent.chrome.userAgent)
        page.stop()
    }

    @Test func `a page the site moved to by itself, without loading, is loaded again where it is`() async throws {
        let server = try EchoServer(pages: ["/app": "<script>history.pushState({}, '', '/app/inner')</script>"])
        let page = WebContent(url: nil, settings: WebSettings(applicationName: "Version/26.0 Safari/605.1.15"))
        page.agents = SiteAgents()
        page.setState(focused: true, visible: true)
        page.load(try #require(URL(string: "http://127.0.0.1:\(server.port)/app")))
        try await waitForObservedState { page.url?.path() == "/app/inner" && !page.isLoading }
        page.appear(as: .firefox)
        try await Poll.until { !page.isLoading && server.header("User-Agent", for: "/app/inner") != nil }
        #expect(server.header("User-Agent", for: "/app/inner") == BrowserAgent.firefox.userAgent)
        page.stop()
    }
}
