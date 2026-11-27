import AemiTestKit
import Foundation
import SunsetRuntime
import Testing

@testable import SunsetWeb
@testable import SunsetWebModel

/// Audit MED-05/HIGH-05: what needs the person's click (sharing the screen) is asked only after a click Sunset saw itself;
/// a frame asking is named.
@MainActor
@Suite("What needs the person's click")
struct UserInputGateTests {
    @Test func `without a click Sunset saw, sharing is refused at once; a click a moment ago lets it ask`() async throws
    {
        let page = WebContent(url: URL(string: "https://call.example"), settings: WebSettings(applicationName: "Test"))
        #expect(!page.hasRecentUserInput)
        #expect(await page.askShare(frameHost: "call.example") == .cancel)
        page.lastUserInput = page.runtime.uptime()
        #expect(page.hasRecentUserInput)
        let asking = Task { await page.askShare(frameHost: "ads.example") }
        try await waitForObservedState { page.shareRequest != nil }
        #expect(page.shareRequest?.frameHost == "ads.example")
        page.shareRequest?.answer(.cancel)
        _ = await asking.value
    }
}
