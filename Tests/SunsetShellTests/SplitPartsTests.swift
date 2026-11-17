import SunsetPane
import Testing

@testable import SunsetShell

/// The owner, 2026-11-17: "one cannot focus on one of those tab by clicking on the inner tab of the split tabs container in
/// the sidebar"; "make sure we can separate any tabs from split tabs anywhere". A split's part shows and focuses its pane;
/// any pane comes out of its split into a tab of its own, in Today, in the Favorites and in the grid.
@MainActor
@Suite("The parts of a split tab")
struct SplitPartsTests {
    private func split(_ harness: TabsHarness) throws -> Workspace.Item {
        let tabs = harness.tabs
        tabs.newTab()
        tabs.split(.right, with: FakeContent(), beside: try #require(tabs.selectedContent))
        return try #require(tabs.workspace.selectedItem)
    }

    @Test func `a click on a part of a split in Today shows the split and focuses that pane`() throws {
        let harness = TabsHarness()
        let tabs = harness.tabs
        let item = try split(harness)
        tabs.newTab()
        tabs.choose(part: item.panes[0], of: .tab(item.id))
        #expect(tabs.workspace.selectedID == item.id && tabs.shownPane == item.panes[0])
        tabs.choose(part: item.panes[1], of: .tab(item.id))
        #expect(tabs.shownPane == item.panes[1])
    }

    @Test func `a click on a part of a kept split shows the entry and focuses that pane`() throws {
        let harness = TabsHarness()
        let tabs = harness.tabs
        let item = try split(harness)
        let entry = try #require(tabs.keep(item: item.id, show: false))
        tabs.newTab()
        tabs.choose(part: item.panes[0], of: .node(entry))
        #expect(tabs.shownEntry?.id == entry && tabs.shownPane == item.panes[0])
    }

    @Test func `a pane comes out of a split into a tab of its own, from Today, the Favorites and the grid`() throws {
        let harness = TabsHarness()
        let tabs = harness.tabs
        tabs.pinned = FavoritesModel()
        let today = try split(harness)
        tabs.separate(pane: today.panes[1])
        #expect(tabs.workspace.items.count == 2 && tabs.workspace.items.allSatisfy { $0.panes.count == 1 })

        let kept = try split(harness)
        let entry = try #require(tabs.keep(item: kept.id, show: false))
        let before = tabs.workspace.count
        tabs.separate(pane: kept.panes[1])
        #expect(tabs.favorites.favorites.entry(entry)?.open?.panes == [kept.panes[0]])
        #expect(tabs.workspace.count == before + 1 && tabs.workspace.items.last?.panes == [kept.panes[1]])

        let pinned = try split(harness)
        let tile = try #require(tabs.pin(item: pinned.id, show: false))
        tabs.separate(pane: pinned.panes[0])
        #expect(tabs.pinned?.favorites.entry(tile)?.open?.panes == [pinned.panes[1]])
        #expect(tabs.workspace.items.contains { $0.panes == [pinned.panes[0]] })
        #expect(harness.made.allSatisfy { !$0.stopped }, "nothing stopped by coming out")
    }
}
