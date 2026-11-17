import Foundation
import Testing
import WebKit

@testable import SunsetWeb

/// Appearing as another browser (roadmap 0022, W-a; the owner's answers of 2026-11-17): Chrome, Edge, Firefox or Safari on
/// macOS, for a site and its subdomains or for every site. The first rung only: what the User-Agent says.
@MainActor
@Suite("Appearing as another browser")
struct BrowserAgentTests {
    @Test func `each preset says what that browser says on a Mac, with the version the build was given`() {
        #expect(BrowserAgent.safari.userAgent == nil, "Sunset as it is: WebKit's own, named as the installed Safari")
        #expect(
            BrowserAgent.chrome.userAgent
                == "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) "
                + "Chrome/\(AgentVersions.chrome).0.0.0 Safari/537.36"
        )
        #expect(BrowserAgent.edge.userAgent?.hasSuffix("Safari/537.36 Edg/\(AgentVersions.edge).0.0.0") == true)
        #expect(BrowserAgent.edge.userAgent?.contains("Chrome/\(AgentVersions.edge).0.0.0") == true)
        #expect(
            BrowserAgent.firefox.userAgent
                == "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:\(AgentVersions.firefox).0) Gecko/20100101 "
                + "Firefox/\(AgentVersions.firefox).0"
        )
        #expect(AgentVersions.chrome > 100 && AgentVersions.edge > 100 && AgentVersions.firefox > 100)
        #expect(BrowserAgent.allCases.map(\.rawValue) == ["safari", "chrome", "edge", "firefox"])
    }

    @Test func `a site's rule is for the site and its subdomains; no rule is the default; a private page keeps none`() {
        let sites = SiteAgents()
        #expect(sites.agent(for: "example.com", default: .safari) == .safari)
        sites.set(.chrome, for: "www.Example.com")
        #expect(sites.agent(for: "example.com", default: .safari) == .chrome)
        #expect(sites.agent(for: "mail.example.com", default: .firefox) == .chrome)
        #expect(sites.agent(for: "notexample.com", default: .firefox) == .firefox)
        #expect(sites.agent(for: "com", default: .safari) == .safari && sites.agent(for: nil, default: .edge) == .edge)
        // A subdomain's own rule comes before its parent's.
        sites.set(.firefox, for: "mail.example.com")
        #expect(sites.agent(for: "a.mail.example.com", default: .safari) == .firefox)
        #expect(sites.rules.map(\.host) == ["example.com", "mail.example.com"])
        sites.set(nil, for: "example.com")
        #expect(sites.agent(for: "example.com", default: .safari) == .safari && sites.rules.count == 1)
    }

    /// What a site receives, read from a server on this machine: by the default, by the site's rule, and again at each
    /// page the view goes to.
    @Test func `a server is sent the User-Agent of its site's preset, and the page's script sees the same`()
        async throws
    {
        let server = try EchoServer()
        let sites = SiteAgents()
        sites.set(.chrome, for: "localhost")
        var settings = WebSettings(applicationName: "Version/26.0 Safari/605.1.15")
        settings.agent = .firefox
        let page = WebContent(url: URL(string: "http://127.0.0.1:\(server.port)/first"), settings: settings)
        page.agents = sites
        page.setState(focused: true, visible: true)
        let view = try #require(page.webView)
        try await loaded(view)
        // 127.0.0.1 has no rule: the default.
        #expect(server.header("User-Agent", for: "/first") == BrowserAgent.firefox.userAgent)
        #expect(server.header("Sec-CH-UA", for: "/first") == nil, "no client hint is sent: WebKit has none")
        // The tab's icon is asked for by Sunset, not by the page: it says the same (seen 2026-11-17: it said
        // "Sunset/7e95475 CFNetwork/… Darwin/…" to a site shown Chrome).
        for _ in 0 ..< 200 where server.header("User-Agent", for: "/favicon.ico") == nil {
            try await Task.sleep(for: .milliseconds(25))
        }
        #expect(server.header("User-Agent", for: "/favicon.ico") == BrowserAgent.firefox.userAgent)
        // The same view goes to a site with a rule.
        view.load(URLRequest(url: try #require(URL(string: "http://localhost:\(server.port)/second"))))
        try await loaded(view)
        #expect(server.header("User-Agent", for: "/second") == BrowserAgent.chrome.userAgent)
        let seen = try await view.evaluateJavaScript("navigator.userAgent") as? String
        #expect(seen == BrowserAgent.chrome.userAgent)
        // And back to a site with none, with the default now Safari: WebKit's own, as before.
        page.settings.agent = .safari
        view.load(URLRequest(url: try #require(URL(string: "http://127.0.0.1:\(server.port)/third"))))
        try await loaded(view)
        let own = try #require(server.header("User-Agent", for: "/third"))
        #expect(
            own.contains("AppleWebKit/605") && own.hasSuffix("Version/26.0 Safari/605.1.15") && !own.contains("Chrome")
        )
        #expect(
            !server.received.contains { $0.contains("CFNetwork") },
            "nothing Sunset asks for says it is not a browser"
        )
        page.stop()
    }

    private func loaded(_ view: WKWebView) async throws {
        for _ in 0 ..< 400 {
            try await Task.sleep(for: .milliseconds(25))
            if !view.isLoading, view.estimatedProgress >= 1 { return }
        }
        Issue.record("the page did not load")
    }
}
