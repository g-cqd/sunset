import AemiTestKit
import AppKit
import Foundation
import Observation
import SunsetTestSupport
import Testing
import WebKit

@testable import SunsetWeb
@testable import SunsetWebModel

/// A page's icon, kept and followed, in a real page: the icon the page names is kept for its site; one the page puts in
/// its place while it runs replaces it.
@MainActor
@Suite("A page's icon, kept", .serialized)
struct WebFaviconTests {
    /// A one-colour square as a `data:` address.
    private static func address(_ colour: NSColor) -> String {
        let image = NSImage(size: NSSize(width: 8, height: 8), flipped: false) { rect in
            colour.setFill()
            rect.fill()
            return true
        }
        let png =
            NSBitmapImageRep(data: image.tiffRepresentation ?? Data())?.representation(using: .png, properties: [:])
            ?? Data()
        return "data:image/png;base64," + png.base64EncodedString()
    }

    @Test(.timeLimit(.minutes(1)))
    func `the icon the page names is kept for its site, and one it changes to replaces it`() async throws {
        let page = WebContent(url: nil, settings: WebSettings(applicationName: "Version/26.0 Safari/605.1.15"))
        let store = FaviconStore()
        page.icons = store
        page.setState(focused: false, visible: true)
        let view = try #require(page.webView)
        let red = Self.address(.red)
        view.loadHTMLString(
            "<html><head><link rel='icon' href='\(red)'></head><body>icons</body></html>",
            baseURL: URL(string: "https://icons.example/")
        )
        try await waitForObservedState { page.favicon != nil }
        try #require(page.favicon != nil)
        #expect(store.isFresh(host: "icons.example", source: URL(string: red)))
        let blue = Self.address(.blue)
        _ = try await view.callAsyncJavaScript(
            "document.querySelector('link[rel~=icon]').href = icon; return 1",
            arguments: ["icon": blue],
            contentWorld: .page
        )
        try await waitUntil { store.isFresh(host: "icons.example", source: URL(string: blue)) }
        #expect(store.isFresh(host: "icons.example", source: URL(string: blue)), "the new one replaced it")
        page.stop()
    }
}
