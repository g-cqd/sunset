import AemiTestKit
import Foundation
import SunsetTestSupport
import Testing
import WebKit

@testable import SunsetWeb
@testable import SunsetWebModel

/// Appearing as another browser: Chrome, Edge, Firefox or Safari on macOS, for a site and its subdomains or for every
/// site. The first rung only: what the User-Agent says.
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
    @Test(.macOS27) func `a server is sent the User-Agent of its site's preset, and the page's script sees the same`()
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
        await RealWait.until { !(server.header("User-Agent", for: "/favicon.ico") == nil) }
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

    /// The second rung: what a page's scripts read first to tell a browser, set to what that browser says. A page that says
    /// Chrome with Apple's vendor is told apart at once.
    @Test(.macOS27)
    func
        `to its scripts a page shown Chrome or Edge has Google's vendor, client hints and window.chrome; Firefox its own`()
        async throws
    {
        let server = try EchoServer()
        func probe(_ agent: BrowserAgent, scripts: Bool = true) async throws -> [String] {
            var settings = WebSettings(applicationName: "Version/26.0 Safari/605.1.15")
            settings.agent = agent
            settings.agentScripts = scripts
            let page = WebContent(
                url: URL(string: "http://127.0.0.1:\(server.port)/\(agent.rawValue)"),
                settings: settings
            )
            page.agents = SiteAgents()
            page.setState(focused: true, visible: true)
            let view = try #require(page.webView)
            try await loaded(view)
            let script = """
                [navigator.vendor, typeof window.chrome, navigator.userAgentData ? navigator.userAgentData.platform : "none",
                 navigator.userAgentData ? navigator.userAgentData.brands.map(b => b.brand + " " + b.version).join(", ") : "none",
                 String(navigator.oscpu), String(navigator.productSub)]
                """
            let read = try await view.evaluateJavaScript(script) as? [String] ?? []
            page.stop()
            return read
        }
        let chrome = try await probe(.chrome)
        #expect(chrome.prefix(3) == ["Google Inc.", "object", "macOS"])
        #expect(
            chrome[3].contains("Google Chrome \(AgentVersions.chrome)")
                && chrome[3].contains("Chromium \(AgentVersions.chrome)")
        )
        let edge = try await probe(.edge)
        #expect(edge[0] == "Google Inc." && edge[3].contains("Microsoft Edge \(AgentVersions.edge)"))
        let firefox = try await probe(.firefox)
        #expect(firefox == ["", "undefined", "none", "none", "Intel Mac OS X 10.15", "20100101"])
        let safari = try await probe(.safari)
        #expect(safari.prefix(4) == ["Apple Computer, Inc.", "undefined", "none", "none"], "Sunset as it is: untouched")
        let headersOnly = try await probe(.chrome, scripts: false)
        #expect(
            headersOnly.prefix(3) == ["Apple Computer, Inc.", "undefined", "none"],
            "`web.agentScripts` off: the first rung only"
        )
    }

    /// Found 2026-11-17: at each key typed the search engine was told "Sunset/<build> CFNetwork/… Darwin/…".
    @Test(.macOS27) func `the request for search suggestions says what a page would, not that it is Sunset`()
        async throws
    {
        let server = try EchoServer()
        let engine = SearchEngine(
            name: "Echo",
            keyword: "e",
            search: "http://127.0.0.1:\(server.port)/search?q=%s",
            suggest: "http://127.0.0.1:\(server.port)/suggest?q=%s"
        )
        var settings = WebSettings(applicationName: "Version/26.0 Safari/605.1.15")
        #expect(
            settings.userAgent
                == "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) "
                + "Version/26.0 Safari/605.1.15",
            "what WebKit says by itself, composed for the requests Sunset makes without a page"
        )
        let source = SuggestionSource()
        source.update("tide", engine: engine, words: "tide", enabled: true, userAgent: settings.userAgent)
        try await waitUntil(timeout: .seconds(20), label: "the server asked for suggestions on \"tide\"") {
            server.header("User-Agent", for: "/suggest?q=tide") != nil
        }
        #expect(server.header("User-Agent", for: "/suggest?q=tide") == settings.userAgent)
        settings.agent = .chrome
        #expect(settings.userAgent == BrowserAgent.chrome.userAgent)
        source.update("tides", engine: engine, words: "tides", enabled: true, userAgent: settings.userAgent)
        try await waitUntil(timeout: .seconds(20), label: "the server asked for suggestions on \"tides\"") {
            server.header("User-Agent", for: "/suggest?q=tides") != nil
        }
        #expect(server.header("User-Agent", for: "/suggest?q=tides") == BrowserAgent.chrome.userAgent)
        #expect(!server.received.contains { $0.contains("CFNetwork") })
    }

    /// Loaded, as WebKit says it by key-value observing: its progress whole, then no longer loading.
    private func loaded(_ view: WKWebView) async throws {
        try await KeyValueProbe(view, \.estimatedProgress).wait(until: { $0 >= 1 }, timeout: .seconds(10))
        try await KeyValueProbe(view, \.isLoading).wait(until: { !$0 }, timeout: .seconds(10))
    }
}
