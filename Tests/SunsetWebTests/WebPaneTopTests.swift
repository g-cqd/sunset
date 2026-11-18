import Testing

@testable import SunsetWeb

/// Roadmap 0045 D (the owner, 2026-11-18: "setting the sidebar to floating when on a webpage creates an odd blank space at
/// the top of the content pane"): with the sidebar floating, a window with no title bar keeps a strip at its top to drag
/// it by, and the page was pushed below it.
@Suite("Where a page starts in its pane")
struct WebPaneTopTests {
    @Test func `a page reaches the top under the strip; a row of its address stays below it`() {
        #expect(WebPaneView.contentTop(topInset: 16, addressRow: false) == 0)
        #expect(WebPaneView.contentTop(topInset: 16, addressRow: true) == 16)
        #expect(WebPaneView.contentTop(topInset: 0, addressRow: true) == 0)
    }
}
