import AppKit
import Testing
import WebKit

@testable import SunsetWeb

@Suite("Web basics pages rely on (roadmap 0029)") @MainActor struct WebBasicsTests {
    @Test func `a page's file field opens a panel for what it asked: one file, several, folders`() {
        let one = FileChoice(multiple: false, folders: false).panel(host: "a.com")
        #expect(one.canChooseFiles && !one.allowsMultipleSelection && !one.canChooseDirectories)
        #expect(one.message == "a.com asks for a file.")
        let many = FileChoice(multiple: true, folders: true).panel(host: "")
        #expect(many.allowsMultipleSelection && many.canChooseDirectories)
        #expect(many.message == "This page asks for files or folders.")
    }

    @Test func `a page can go fullscreen and be pinched`() throws {
        let page = WebContent(url: nil, settings: WebSettings())
        page.setState(focused: true, visible: true)
        let view = try #require(page.webView)
        #expect(view.configuration.preferences.isElementFullscreenEnabled && view.allowsMagnification)
    }

    @Test func `a page whose process ended shows as a failure that Reload clears`() throws {
        let page = WebContent(url: URL(string: "https://a.com/x"), settings: WebSettings())
        page.setState(focused: true, visible: true)
        let view = try #require(page.webView)
        view.navigationDelegate?.webViewWebContentProcessDidTerminate?(view)
        let failure = try #require(page.failure)
        #expect(!failure.isCertificate && failure.url == URL(string: "https://a.com/x"))
        #expect(failure.heading == "This page stopped")
        page.reload()
        #expect(page.failure == nil)
    }
}
