import AppKit
import Foundation
import SunsetTestSupport
import Testing
import WebKit

@testable import SunsetWeb
@testable import SunsetWebModel

/// Fields in frames (ADR-0094, t103): a frame of the page's origin, and one inside it, tells its fields' focus at their
/// place in the page (each frame's place, border and padding added) and is filled where its field is; a frame of
/// another origin (another host's, or a sandboxed one, whose origin is its own) tells nothing.
@MainActor @Suite("Sign-in fields in frames", .serialized, .timeLimit(.minutes(1)))
final class PasswordFillFrameTests {
    private var windows: [NSWindow] = []
    private var hosts: [PasswordFillTests.Host] = []
    private var pages: [WebContent] = []

    deinit {
        MainActor.assumeIsolated { windows.forEach { $0.close() } }
    }

    static let frameStyle = "position:absolute;width:300px;height:140px;border:7px solid;padding:3px;margin:0"
    static let page = """
        <body style="margin:0"><input id="top" autocomplete="username" style="position:absolute;left:5px;top:5px">
        <iframe id="same" style="\(frameStyle);left:100px;top:150px" srcdoc="<body style='margin:0'><form>\
        <input id=u autocomplete=username style='margin:0'><input id=p type=password></form>"></iframe>
        <iframe id="outer" style="\(frameStyle);left:20px;top:300px" srcdoc="<body style='margin:0'>\
        <iframe id=inner style='position:absolute;left:40px;top:10px;border:0;margin:0' \
        srcdoc='<body style=margin:0><input id=u autocomplete=username>'></iframe>"></iframe>
        <iframe id="sandboxed" sandbox="allow-scripts" style="\(frameStyle);left:400px;top:0" srcdoc="\(focusOnMessage)">
        </iframe>
        </body>
        """
    /// A frame's page whose field takes the keyboard when the page above posts to it.
    static let focusOnMessage = """
        <input id=u autocomplete=username><script>onmessage = () => document.getElementById('u').focus()</script>
        """

    private func page(_ html: String = page, at address: String = "https://example.com/signin") async throws -> (
        WebContent, WKWebView, PasswordFillTests.Host
    ) {
        let page = WebContent(url: URL(string: address), settings: WebSettings(applicationName: "x"))
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
        view.loadHTMLString(html, baseURL: URL(string: address))
        await until { !page.isLoading && page.webView?.url != nil }
        // Until every frame's script is in.
        _ = try await run("await new Promise(r => setTimeout(r, 300))", in: view)
        return (page, view, host)
    }

    private func run(_ script: String, in view: WKWebView) async throws -> Any? {
        try await view.callAsyncJavaScript(script, contentWorld: .page)
    }

    /// The document of the same-origin frame `path` leads to, as a script's expression.
    private static func document(_ path: [String]) -> String {
        path.reduce("document") { "\($0).getElementById('\($1)').contentDocument" }
    }

    @Test(.macOS27) func `a field of a frame of the page's origin is told at its place in the page, and filled there`()
        async throws
    {
        let (page, view, host) = try await page()
        _ = try await run("\(Self.document(["same"])).getElementById('u').focus()", in: view)
        await host.wait { $0.focused != nil }
        let field = try #require(host.focused)
        #expect(field.role == .username && field.origin == URL(string: "https://example.com"))
        #expect(field.frame.minX == 110 && field.frame.minY == 160, "the frame's place, border and padding")
        let filled = await page.fill(username: "ada", password: "pw1", for: field.origin)
        #expect(filled)
        let values = try await run(
            "const d = \(Self.document(["same"])); return d.getElementById('u').value + '|' + d.getElementById('p').value",
            in: view
        )
        #expect(values as? String == "ada|pw1")
        #expect(try await run("return document.getElementById('top').value", in: view) as? String == "")
    }

    @Test func `a frame in a frame of the page's origin adds both places`() async throws {
        let (_, view, host) = try await page()
        _ = try await run("\(Self.document(["outer", "inner"])).getElementById('u').focus()", in: view)
        await host.wait { $0.focused != nil }
        let field = try #require(host.focused)
        #expect(field.frame.minX == 20 + 10 + 40 && field.frame.minY == 300 + 10 + 10)
    }

    @Test func `a frame of another origin tells nothing`() async throws {
        let server = try await AnsweringProxy.start(answering: Self.focusOnMessage)
        defer { server.stop() }
        let frames = """
            <body style="margin:0"><input id="top" autocomplete="username" style="position:absolute;left:5px;top:5px">
            <iframe id="other" src="http://127.0.0.1:\(server.port)/" style="\(Self.frameStyle);left:0;top:50px"></iframe>
            \(Self.page)
            """
        let (_, view, host) = try await page(frames, at: "http://localhost:\(server.port)/signin")
        #expect(!server.requests.isEmpty, "the page's load waited for its frames")
        _ = try await run("await new Promise(r => setTimeout(r, 300))", in: view)
        for frame in ["other", "sandboxed"] {
            _ = try await run("document.getElementById('\(frame)').contentWindow.postMessage('focus', '*')", in: view)
            _ = try await run("await new Promise(r => setTimeout(r, 300))", in: view)
            let focusedThere = try await run("return document.activeElement.id", in: view)
            #expect(focusedThere as? String == frame, "the field over there has the keyboard")
        }
        _ = try await run("document.getElementById('top').focus()", in: view)
        await host.wait(for: 1)
        #expect(host.events == ["focus username"] && host.focused?.frame.minX == 5)
    }
}
