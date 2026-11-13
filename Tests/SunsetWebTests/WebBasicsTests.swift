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

@Suite("The address of the link under the pointer") @MainActor struct LinkStatusTests {
    @Test func `nothing for no link; a page's text is shown without control characters, cut in the middle`() {
        #expect(LinkStatus.text(nil) == nil && LinkStatus.text("") == nil && LinkStatus.text(42) == nil)
        #expect(LinkStatus.text("https://a.com/x") == "https://a.com/x")
        #expect(LinkStatus.text("https://a.com/\n\u{1B}[31mx\u{202E}") == "https://a.com/[31mx")
        let long = "https://a.com/" + String(repeating: "p", count: 400) + "/end"
        let shown = LinkStatus.text(long)
        #expect(shown?.count == LinkStatus.limit && shown?.hasPrefix("https://a.com/ppp") == true)
        #expect(shown?.hasSuffix("/end") == true && shown?.contains("\u{2026}") == true)
    }

    @Test func `each page has its own script world and handler; a page opened by another does not share them`() throws {
        let page = WebContent(url: nil, settings: WebSettings())
        page.setState(focused: true, visible: true)
        let controller = try #require(page.webView?.configuration.userContentController)
        #expect(controller.userScripts.count == 1 && !controller.userScripts[0].isForMainFrameOnly)
        let opened = WebContent(configuration: try #require(page.webView?.configuration), settings: WebSettings())
        #expect(opened.webView?.configuration.userContentController !== controller)
        #expect(opened.webView?.configuration.userContentController.userScripts.count == 1)
        page.hoveredLink = "x"
        page.linkHovered("")
        #expect(page.hoveredLink == nil)
        page.linkHovered("https://a.com/")
        #expect(page.hoveredLink == "https://a.com/")
    }
}
