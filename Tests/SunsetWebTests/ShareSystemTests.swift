import Foundation
import Testing
import WebKit

@testable import SunsetWeb
@testable import SunsetWebModel

/// ADR-0085 (the owner, 2026-11-19: "clicking on screen and windows i'd expect to get the native experience"): WebKit in an
/// app shows no picker and takes the main screen or a window of its choosing (probed), so a page never reaches it; "Screen,
/// Window or App…" is macOS's picker, and Sunset captures what is picked.
@MainActor @Suite("Share: a screen, a window or an app")
struct ShareSystemTests {
    @Test func `the page's wrapper never calls WebKit's own getDisplayMedia`() {
        let page = WebContent(url: URL(string: "https://meet.example/"), settings: WebSettings())
        let script = ShareWrapper.install(on: WKWebViewConfiguration(), for: page).script
        #expect(!script.contains("original"), "the page's own getDisplayMedia is not kept to be called")
        #expect(script.contains("choice !== \"tab\""), "anything but a stream Sunset makes is refused")
    }
}
