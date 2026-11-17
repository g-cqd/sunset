import AppKit
import Foundation
import Observation
import Testing
import WebKit

@testable import SunsetWeb

/// The picture of a page's notification (roadmap 0036 E), in a real page: fetched as the page, made small, in a file.
@MainActor
@Suite("A page's notification picture")
struct WebNotificationIconTests {
    @Test(.timeLimit(.minutes(1)))
    func `a notification's picture is made small and written to a file; one that is not a picture gives none`()
        async throws
    {
        let page = WebContent(url: nil, settings: WebSettings(applicationName: "Version/26.0 Safari/605.1.15"))
        page.setState(focused: false, visible: true)
        let big = NSImage(size: NSSize(width: 512, height: 512), flipped: false) { rect in
            NSColor.green.setFill()
            rect.fill()
            return true
        }
        let tiff = try #require(big.tiffRepresentation)
        let png = try #require(NSBitmapImageRep(data: tiff)?.representation(using: .png, properties: [:]))
        let note = WebNotification(
            id: 1,
            title: "a",
            body: "",
            host: "chat.example",
            icon: "data:image/png;base64," + png.base64EncodedString()
        )
        let file = try #require(await page.notificationIcon(for: note))
        defer { try? FileManager.default.removeItem(at: file) }
        let kept = try #require(NSImage(contentsOf: file)?.representations.first)
        #expect(kept.pixelsWide == 256 && kept.pixelsHigh == 256)
        let notPicture = WebNotification(
            id: 2,
            title: "b",
            body: "",
            host: "chat.example",
            icon: "data:text/plain,hello"
        )
        #expect(await page.notificationIcon(for: notPicture) == nil)
        page.stop()
    }
}
