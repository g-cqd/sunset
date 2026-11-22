import SunsetPane
import Testing

@testable import SunsetShellModel

/// A terminal or a document shared into a call had no mark on its tab, where a page has one. One count for every kind
/// of content: while anything shares a pane, its tab is marked as a screen shared.
@MainActor @Suite("A shared tab's mark, for every kind")
struct SharedMarkTests {
    @Test func `marked while shared, by every share at once; unmarked once the last stops`() {
        let shares = SharedPanes()
        let pane = FakeContent(PaneDescriptor(kind: "terminal"))
        #expect(shares.mark(pane) == nil)
        shares.change(pane, sharing: true)
        shares.change(pane, sharing: true)
        #expect(shares.mark(pane) == .screen)
        shares.change(pane, sharing: false)
        #expect(shares.mark(pane) == .screen, "one call still shares it")
        shares.change(pane, sharing: false)
        shares.change(pane, sharing: false)
        #expect(shares.mark(pane) == nil && shares.count(pane) == 0, "never below none")
    }

    @Test func `a content's mark says so by default, the shared registry's`() {
        let pane = FakeContent(PaneDescriptor(kind: "terminal"))
        SharedPanes.shared.change(pane, sharing: true)
        #expect(pane.captureMark == .screen)
        SharedPanes.shared.change(pane, sharing: false)
        #expect(pane.captureMark == nil)
    }
}
