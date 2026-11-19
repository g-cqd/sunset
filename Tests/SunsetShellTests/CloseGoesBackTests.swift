import Testing

@testable import SunsetPane
@testable import SunsetShell
@testable import SunsetShellModel

/// The owner's note n4 (2026-11-18): "when closing a tab, the most recent tab that was focused before this one should be
/// focused again (could be a configurable setting as well)".
@MainActor @Suite("Closing the shown tab shows the one shown before it")
struct CloseGoesBackTests {
    @Test func `the tab shown before, not the neighbour; off, the neighbour as before`() {
        for goesBack in [true, false] {
            let harness = TabsHarness()
            harness.tabs.closeGoesBack = goesBack
            for _ in 0 ..< 3 { harness.tabs.newTab() }
            let items = harness.tabs.workspace.items.map(\.id)
            // Shown in turn: the third, the first, the second; the second closes. Its neighbour is the third; shown
            // before it, the first.
            harness.tabs.select(item: items[2])
            harness.tabs.select(item: items[0])
            harness.tabs.select(item: items[1])
            harness.tabs.close(item: items[1])
            #expect(harness.tabs.workspace.selectedID == (goesBack ? items[0] : items[2]), "goes back: \(goesBack)")
            // Shown before the first: the third (the second is gone).
            harness.tabs.close(item: items[0])
            #expect(harness.tabs.workspace.selectedID == items[2])
        }
    }

    @Test func `closing with Cmd-W, or the program ending, goes back the same way`() {
        let harness = TabsHarness()
        for _ in 0 ..< 3 { harness.tabs.newTab() }
        let items = harness.tabs.workspace.items.map(\.id)
        harness.tabs.select(item: items[2])
        harness.tabs.select(item: items[0])
        harness.tabs.select(item: items[1])
        harness.tabs.closeSelected()
        #expect(harness.tabs.workspace.selectedID == items[0])
    }
}
