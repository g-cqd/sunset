import Testing

@testable import SunsetCore

@Suite("Viewport reads outside the screen") struct ScreenViewportBoundsTests {
    /// The window can be resized while the app still holds the last snapshot: a pointer position worked out for the new size must not trap on the old one.
    @Test func `a cell outside the screen is an empty cell, not a trap`() {
        let t = terminal("hello\r\nworld")
        let screen = t.screen
        #expect(screen.viewportCell(row: 50, column: 2, scrolledBack: 0) == .empty)
        #expect(screen.viewportCell(row: 1, column: 500, scrolledBack: 0) == .empty)
        #expect(screen.viewportCell(row: -3, column: 0, scrolledBack: 0) == .empty)
        #expect(screen.viewportCell(row: 0, column: -1, scrolledBack: 0) == .empty)
    }

    @Test func `a link or a link id outside the screen is none`() {
        let t = terminal("\(esc)]8;;https://example.com\(esc)\\link\(esc)]8;;\(esc)\\")
        let screen = t.screen
        #expect(screen.viewportLinkID(row: 0, column: 1, scrolledBack: 0) != nil)
        #expect(screen.viewportLinkID(row: 99, column: 1, scrolledBack: 0) == nil)
        #expect(screen.viewportLink(row: 0, column: 99, scrolledBack: 0) == nil)
    }
}
