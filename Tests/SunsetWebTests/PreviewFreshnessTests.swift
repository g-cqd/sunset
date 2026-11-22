import AppKit
import Foundation
import SunsetRuntime
import SunsetTestSupport
import Testing
import WebKit

@testable import SunsetWeb
@testable import SunsetWebModel

/// A tab's preview is not kept forever (the owner's note n95): pointed at, a hidden page whose picture is older than half
/// a minute is pictured again as it is now (in a window of its own off screen, then put back), the old picture shown
/// until the new one comes; a recent one is kept.
@MainActor @Suite("Previews made again when old", .serialized, .timeLimit(.minutes(1)))
final class PreviewFreshnessTests {
    private var windows: [NSWindow] = []

    deinit {
        MainActor.assumeIsolated { windows.forEach { $0.close() } }
    }

    /// The red of the picture's middle pixel, 0 to 255.
    private func red(_ picture: CGImage?) throws -> Int {
        let image = try #require(picture)
        let bitmap = NSBitmapImageRep(cgImage: image)
        let color = try #require(
            bitmap.colorAt(x: bitmap.pixelsWide / 2, y: bitmap.pixelsHigh / 2)?.usingColorSpace(.sRGB)
        )
        return Int((color.redComponent * 255).rounded())
    }

    @Test func `an old picture of a hidden page is made again; a recent one is kept`() async throws {
        let time = TestTime()
        let page = WebContent(url: URL(string: "https://example.com/"), settings: WebSettings(applicationName: "x"))
        page.runtime = time.runtime
        page.setState(focused: false, visible: true)
        let view = try #require(page.webView)
        view.frame = CGRect(x: 0, y: 0, width: 200, height: 120)
        let window = NSWindow(contentRect: view.frame, styleMask: [.borderless], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.contentView = view
        windows.append(window)
        view.loadHTMLString(
            "<body style='margin:0;background:rgb(255,0,0)'></body>",
            baseURL: URL(string: "https://example.com/")
        )
        await until { !page.isLoading && page.webView?.url != nil }
        page.takePicture()
        await until { page.picture != nil }
        #expect(try red(page.picture) > 200)
        // Hidden: out of its window, its page changes meanwhile.
        window.contentView = nil
        page.setState(focused: false, visible: false)
        _ = try await view.callAsyncJavaScript("document.body.style.background = 'rgb(0,0,255)'", contentWorld: .page)
        time.advance(.seconds(10))
        page.refreshPicture(olderThan: .seconds(30))
        let kept = try red(page.picture)
        #expect(!page.takingPicture && kept > 200, "ten seconds old: kept")
        time.advance(.seconds(25))
        let old = page.picture
        page.refreshPicture(olderThan: .seconds(30))
        await until { page.picture !== old }
        #expect(try red(page.picture) < 50, "half a minute old: made again, as the page is now")
        #expect(view.window == nil, "put back where it was: out of any window")
    }
}
