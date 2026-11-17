import Foundation
import Testing
import WebKit

@testable import SunsetWeb

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
        #expect(controller.userScripts.count == 2 && controller.userScripts.allSatisfy { !$0.isForMainFrameOnly })
        let opened = WebContent(configuration: try #require(page.webView?.configuration), settings: WebSettings())
        #expect(opened.webView?.configuration.userContentController !== controller)
        #expect(opened.webView?.configuration.userContentController.userScripts.count == 2)
        page.hoveredLink = "x"
        page.linkHovered("")
        #expect(page.hoveredLink == nil)
        page.linkHovered("https://a.com/")
        #expect(page.hoveredLink == "https://a.com/")
    }
}
