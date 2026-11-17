import AppKit
import Foundation
import Observation
import Testing
import WebKit

@testable import SunsetWeb

/// The owner, 2026-11-17 (roadmap 0035 C): "there is still no preview for regular web tabs". A page hidden keeps a picture of
/// itself, taken while it is still drawn, for its tab's preview.
@MainActor @Suite("A page's picture", .timeLimit(.minutes(1)))
struct WebPictureTests {
    private let settings = WebSettings(applicationName: "Version/26.0 Safari/605.1.15")

    /// The page's picture once it has one: waited for as a change of `picture`, never on a clock.
    private func picture(of page: WebContent) async -> CGImage? {
        while page.picture == nil {
            await withCheckedContinuation { (done: CheckedContinuation<Void, Never>) in
                withObservationTracking {
                    _ = page.picture
                } onChange: {
                    done.resume()
                }
            }
        }
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
}
