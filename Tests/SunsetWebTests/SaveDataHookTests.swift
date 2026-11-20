import Foundation
import Testing
import WebKit

@testable import SunsetWeb
@testable import SunsetWebModel

/// Download Video: WebKit asks the UI delegate whether it saves data (`_webView:saveDataToFile:…`, probed 2026-11-20); no
/// answer, nothing happens.
@MainActor @Suite("A film's bytes WebKit hands over")
struct SaveDataHookTests {
    @Test func `the page's UI delegate takes them`() throws {
        let page = WebContent(url: nil, settings: WebSettings(applicationName: "Version/26.0 Safari/605.1.15"))
        page.setState(focused: true, visible: true)
        defer { page.stop() }
        let view = try #require(page.webView)
        let delegate = try #require(view.uiDelegate as? NSObject)
        #expect(
            delegate.responds(
                to: NSSelectorFromString("_webView:saveDataToFile:suggestedFilename:mimeType:originatingURL:")
            )
        )
    }
}
