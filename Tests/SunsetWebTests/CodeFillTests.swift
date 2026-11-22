import AppKit
import Foundation
import Testing
import WebKit

@testable import SunsetWeb
@testable import SunsetWebModel

/// One-time codes into pages (roadmap 0094 F): a code's field is told as one (its `one-time-code` token, or a short
/// numeric field named for a code); filled, the code goes into it, or one character a box into a code split in boxes.
@MainActor @Suite("One-time codes into pages", .serialized, .timeLimit(.minutes(1)))
final class CodeFillTests {
    private var windows: [NSWindow] = []
    private var hosts: [PasswordFillTests.Host] = []
    private var pages: [WebContent] = []

    deinit {
        MainActor.assumeIsolated { windows.forEach { $0.close() } }
    }

    static let page = """
        <input id="tagged" autocomplete="one-time-code">
        <input id="named" name="otp_code" inputmode="numeric" maxlength="6">
        <input id="search" type="search">
        <div id="boxes"><input maxlength="1" id="b0"><input maxlength="1" id="b1"><input maxlength="1" id="b2"><input maxlength="1" id="b3"><input maxlength="1" id="b4"><input maxlength="1" id="b5"></div>
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
        view.loadHTMLString(Self.page, baseURL: URL(string: "https://example.com/verify"))
        await until { !page.isLoading && page.webView?.url != nil }
        return (page, view, host)
    }

    private func run(_ script: String, in view: WKWebView) async throws -> Any? {
        try await view.callAsyncJavaScript(script, contentWorld: .page)
    }

    @Test func `a code's field is told as one, by its token or its name; a search field is not`() async throws {
        let (_, view, host) = try await page()
        for id in ["tagged", "named", "search", "b0"] {
            _ = try await run(
                "document.getElementById('\(id)').focus()",
                in: view
            )
        }
        await host.wait(for: 4)
        #expect(host.events == ["focus oneTimeCode", "focus oneTimeCode", "blur", "focus oneTimeCode"])
    }

    @Test func `filled into its field, or one character a box`() async throws {
        let (page, view, _) = try await page()
        _ = try await run("document.getElementById('tagged').focus()", in: view)
        #expect(await page.fillCode("123456", for: try #require(URL(string: "https://example.com"))))
        #expect(try await run("return document.getElementById('tagged').value", in: view) as? String == "123456")
        _ = try await run("document.getElementById('b0').focus()", in: view)
        #expect(await page.fillCode("654321", for: try #require(URL(string: "https://example.com"))))
        let boxes = try await run(
            "return [...document.querySelectorAll('#boxes input')].map(i => i.value).join('')",
            in: view
        )
        #expect(boxes as? String == "654321")
    }
}
