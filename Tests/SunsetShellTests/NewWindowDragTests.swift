import SunsetPane
import Testing

@testable import SunsetShell
@testable import SunsetShellModel

/// The owner, 2026-11-27: a tab dragged out of the window (or dropped with Option) goes to a new window of its Space,
/// with the rest of the selection, whatever it is: a pinned tab leaves the grid for Today.
@MainActor
@Suite("Tabs dragged to a new window")
struct NewWindowDragTests {
    private func window() -> TabsModel {
        let tabs = TabsHarness().tabs
        tabs.pinned = FavoritesModel()
        return tabs
    }

    @Test func `the selection dragged goes, its tabs in Today; the window shows a tab that stays`() throws {
        let tabs = window()
        tabs.newTab()
        tabs.newTab()
        tabs.newTab()
        let ids = tabs.workspace.items.map(\.id)
        tabs.select(item: ids[2])
        _ = tabs.click(.tab(ids[1]), command: true, shift: false)
        #expect(tabs.rows(actingOn: .tab(ids[2])) == [.tab(ids[1]), .tab(ids[2])])
        var opened: [Workspace.ItemID] = []
        tabs.openInNewWindow = { opened = $0 }
        _ = tabs.itemProvider(for: .item(ids[2]))
        tabs.openDraggedInNewWindow()
        #expect(Set(opened) == Set(ids[1 ... 2]))
        #expect(tabs.workspace.selectedID == ids[0] && tabs.dragged == nil)
    }

    @Test func `a pinned tab leaves the grid and goes as a tab of Today`() throws {
        let tabs = window()
        tabs.newTab()
        tabs.newTab()
        let tile = try #require(tabs.pin(item: tabs.workspace.items[0].id, show: false))
        var opened: [Workspace.ItemID] = []
        tabs.openInNewWindow = { opened = $0 }
        _ = tabs.itemProvider(for: .entry(tile))
        tabs.openDraggedInNewWindow()
        #expect(tabs.pinned?.favorites.entry(tile) == nil)
        #expect(opened.count == 1 && tabs.workspace.items.contains { $0.id == opened[0] })
    }

    @Test func `a pane of a split goes alone, out of its split`() throws {
        let tabs = window()
        tabs.newTab()
        tabs.split(.right, with: FakeContent(), beside: try #require(tabs.selectedContent))
        let split = try #require(tabs.workspace.selectedItem)
        var opened: [Workspace.ItemID] = []
        tabs.openInNewWindow = { opened = $0 }
        _ = tabs.itemProvider(for: .pane(split.panes[1]))
        tabs.openDraggedInNewWindow()
        let moved = try #require(tabs.workspace.items.first { $0.id == opened.first })
        #expect(moved.panes == [split.panes[1]])
    }
}
