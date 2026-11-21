import Testing

@testable import SunsetWeb
@testable import SunsetWebModel

/// Roadmap 0045 D (the owner, 2026-11-18: "setting the sidebar to floating when on a webpage creates an odd blank space at
/// the top of the content pane"): with the sidebar floating, a window with no title bar keeps a strip at its top to drag
/// it by, and the page was pushed below it.
@Suite("Where a page starts in its pane")
@MainActor
struct WebPaneTopTests {
    /// Roadmap 0055 D (the owner's note n41, his answer "keep, make it float"): the row of the page's own address floats over
    /// the page's top, below the strip, revealed there; the page itself always reaches the top.
    @Test func `a page reaches the top under the strip; its address row floats over it, below the strip`() {
        #expect(WebPaneView.contentTop(topInset: 16, addressRow: false) == 0)
        #expect(WebPaneView.contentTop(topInset: 16, addressRow: true) == 0)
        #expect(WebPaneView.addressRowTop(topInset: 16) == 16)
        #expect(WebPaneView.addressRowTop(topInset: 0) == 0)
    }
}
