import SunsetPane
import Testing

@testable import SunsetShell

/// The owner, 2026-11-17 (note n1): "switching to a web page first shows an empty grayish page and is not instantaneous".
/// A page is made only when its tab is first shown; the pointer on its row comes first, so the row hovered asks its contents
/// to get ready (a page starts loading), without showing them.
@MainActor
@Suite("A tab gets ready as its row is pointed at")
struct TabsWarmTests {
    @Test func `the contents of the tab, the open favourite or the tile under the pointer are asked to get ready`()
        throws
    {
        let harness = TabsHarness()
        let tabs = harness.tabs
        tabs.newTab()
        let first = try #require(harness.made.last)
        let firstID = try #require(tabs.workspace.selectedID)
        tabs.newTab()
        #expect(first.readied == 0)
        tabs.hoveredItem = firstID
        #expect(first.readied == 1)
        tabs.hoveredItem = nil
        #expect(first.readied == 1)

        let kept = try #require(harness.made.last)
        let keptTab = try #require(tabs.workspace.selectedID)
        let entry = try #require(tabs.keep(item: keptTab, show: false))
        tabs.hoveredItem = tabs.hoverID(entry: entry)
        #expect(kept.readied == 1)
    }
}
