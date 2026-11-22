import AppKit
import Foundation
import Testing
import WebKit

@testable import SunsetWeb
@testable import SunsetWebModel

/// The picture in picture window's button that goes back to the page: WebKit asks the page's delegate
/// (`_webViewFullscreenMayReturnToInline:`, read in WebKit's `VideoPresentationInterfaceMac`, `pipShouldClose:`), and
/// Sunset shows the page's tab, as a card's Go There does.
@MainActor @Suite("Back to the tab from picture in picture")
struct PictureInPictureReturnTests {
    @Test func `the page's delegate is asked, and its tab is shown`() throws {
        let page = WebContent(url: URL(string: "https://media.example/"), settings: WebSettings(applicationName: "x"))
        let center = NowPlaying()
        page.nowPlaying = center
        var shown: [WebContent] = []
        center.goThere = { shown.append($0) }
        page.setState(focused: false, visible: true)
        let view = try #require(page.webView)
        let delegate = try #require(view.uiDelegate as? NSObject)
        let selector = NSSelectorFromString("_webViewFullscreenMayReturnToInline:")
        #expect(delegate.responds(to: selector))
        _ = delegate.perform(selector, with: view)
        #expect(shown.count == 1 && shown.first === page)
        page.stop()
    }
}
