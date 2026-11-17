import AppKit
import Foundation
import Testing
import WebKit

@testable import SunsetWeb

/// Roadmap 0042 D: a page whose text changes while its title does not (a document edited, a list that grows) is pictured
/// again for its tab's card, as one whose title changes is (0037 A).
@MainActor @Suite("A page's picture follows its text", .timeLimit(.minutes(1)))
struct WebPictureTextTests {
    @Test func `a page pictured once is pictured again when its text changes and its title does not`() async throws {
        let page = WebContent(url: nil, settings: WebSettings(applicationName: "Version/26.0 Safari/605.1.15"))
        page.setState(focused: true, visible: true)
        let view = try #require(page.webView)
        let window = NSWindow(
            contentRect: CGRect(x: 0, y: 0, width: 320, height: 200),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.isReleasedWhenClosed = false
        window.contentView = view
        view.loadHTMLString("<title>same</title><body><p id='p'>a</p></body>", baseURL: nil)
        await Waiting.until { page.pageTitle == "same" && !page.isLoading }
        page.takePicture()
        await Waiting.until { page.picture != nil }
        let first = try #require(page.picture)
        _ = try await view.evaluateJavaScript("document.getElementById('p').textContent = 'b, and more'; 1")
        await Waiting.until { page.picture !== first }
        #expect(page.picture !== first, "pictured again as its text changed")
        #expect(page.pageTitle == "same")
        window.close()
        page.stop()
    }
}
