import AppKit
import Foundation
import Observation
import Testing
import WebKit

@testable import SunsetWeb
@testable import SunsetWebModel

/// The owner, 2026-11-17 (roadmap 0035 C): "there is still no preview for regular web tabs". A page hidden keeps a picture of
/// itself, taken while it is still drawn, for its tab's preview.
@MainActor @Suite("A page's picture", .timeLimit(.minutes(1)))
struct WebPictureTests {
    private let settings = WebSettings(applicationName: "Version/26.0 Safari/605.1.15")

    /// The page's picture once it has one: waited for as a change of `picture`, never on a clock.
    private func picture(of page: WebContent) async -> CGImage? {
        // Given up when the test's time limit cancels it, so that a regression fails instead of hanging.
        await Waiting.until { page.picture != nil }
        return page.picture
    }

    @Test func `a page hidden after it was shown in a window has its picture`() async throws {
        let page = WebContent(url: nil, settings: settings)
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
        view.loadHTMLString("<body style='background: rgb(255, 0, 0)'></body>", baseURL: nil)
        #expect(page.picture == nil)
        page.setState(focused: false, visible: false)
        try #require(page.takingPicture, "asked for as it is hidden")
        let image = try #require(await picture(of: page))
        #expect(image.width > 0 && image.height > 0)
        window.close()
        page.stop()
    }

    @Test func `a page never shown takes no picture`() {
        let page = WebContent(url: nil, settings: settings)
        page.setState(focused: false, visible: false)
        page.takePicture()
        #expect(!page.takingPicture && page.picture == nil && page.webView == nil)
    }

    /// 0035's "not done" (roadmap 0036 D): a page pictured once (another window shows its picture) is pictured again when it
    /// has loaded something new, so that the picture follows it.
    @Test(.timeLimit(.minutes(1)))
    func `a page pictured once is pictured again when it has loaded something new`() async throws {
        let page = WebContent(url: nil, settings: settings)
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
        view.loadHTMLString("<body style='background: rgb(255, 0, 0)'></body>", baseURL: nil)
        page.takePicture()
        let first = try #require(await picture(of: page))
        view.loadHTMLString("<body style='background: rgb(0, 0, 255)'></body>", baseURL: nil)
        await Waiting.until { page.picture !== first }
        #expect(page.picture !== first, "a new picture once the new page loaded")
        window.close()
        page.stop()
    }

    /// Roadmap 0037 A: a page that changes without loading (a chat's title counting what is unread) is pictured again.
    @Test(.timeLimit(.minutes(1)))
    func `a page pictured once is pictured again when its title changes`() async throws {
        let page = WebContent(url: nil, settings: settings)
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
        view.loadHTMLString("<title>a</title><body>a</body>", baseURL: nil)
        await Waiting.until { page.pageTitle == "a" && !page.isLoading }
        page.takePicture()
        let first = try #require(await picture(of: page))
        _ = try await view.evaluateJavaScript("document.title = 'b (1)'; document.body.textContent = 'b'; 1")
        await Waiting.until { page.picture !== first }
        #expect(page.picture !== first, "pictured again as its title changed")
        window.close()
        page.stop()
    }
}
