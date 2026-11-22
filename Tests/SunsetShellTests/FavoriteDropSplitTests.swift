import Foundation
import SunsetPane
import Testing

@testable import SunsetShell
@testable import SunsetShellModel

/// "i can't still drop a tab on a favorite and expect it to split". A tab dropped on a favorite row's middle splits with
/// it, as a favorite dropped on a tab's does (`FavoritesSplitTests`): the favorite leaves the Favorites as a tab, the
/// dropped tab joins it. Its top and bottom quarters still put the tab before or after it.
@MainActor
@Suite("A tab dropped on a favorite")
struct FavoriteDropSplitTests {
    private func window() -> TabsModel {
        let tabs = TabsModel()
        tabs.makeContent = { FakeContent($0) }
        tabs.pinned = FavoritesModel()
        return tabs
    }

    @Test func `on the middle of a favorite's row, a tab splits with it; the favorite leaves the Favorites`() throws {
        let tabs = window()
        tabs.newTab()
        tabs.newTab()
        tabs.newTab()
        let kept = try #require(tabs.keep(item: tabs.workspace.items[0].id))
        let dragged = tabs.workspace.items[0].id
        _ = tabs.itemProvider(for: .item(dragged))
        #expect(tabs.canDrop(onEntry: kept, action: .split(.left)))
        #expect(tabs.dropDragged(onEntry: kept, action: .split(.left)))
        #expect(tabs.favorites.favorites.entry(kept) == nil, "it left the Favorites")
        let split = try #require(tabs.workspace.items.first { $0.panes.count == 2 })
        #expect(split.id == dragged || tabs.workspace.items.allSatisfy { $0.id != dragged }, "the dragged tab is in it")
        #expect(tabs.workspace.count == 2)
    }

    @Test func `a pane of a split dropped there splits with the favorite too`() throws {
        let tabs = window()
        tabs.newTab()
        tabs.newTab()
        tabs.newSplit(.right)
        let kept = try #require(tabs.keep(item: tabs.workspace.items[0].id))
        let pane = try #require(tabs.workspace.items.first { $0.panes.count == 2 }?.focused)
        _ = tabs.itemProvider(for: .pane(pane))
        #expect(tabs.dropDragged(onEntry: kept, action: .split(.right)))
        #expect(tabs.favorites.favorites.entry(kept) == nil)
        #expect(tabs.workspace.items.contains { $0.panes.contains(pane) && $0.panes.count == 2 })
    }

    @Test func `on its top or bottom quarter, the tab goes before or after it, as before`() throws {
        let tabs = window()
        tabs.newTab()
        tabs.newTab()
        let kept = try #require(tabs.keep(item: tabs.workspace.items[0].id))
        _ = tabs.itemProvider(for: .item(tabs.workspace.items[0].id))
        #expect(tabs.canDrop(onEntry: kept, action: .moveAfter))
        #expect(tabs.dropDragged(onEntry: kept, action: .moveAfter))
        #expect(tabs.favorites.favorites.entry(kept) != nil, "still a favorite")
        #expect(tabs.favorites.favorites.entries.count == 2)
    }

    @Test func `a pinned tile does not split with a favorite, nor a favorite with itself`() throws {
        let tabs = window()
        tabs.newTab()
        tabs.newTab()
        tabs.newTab()
        let kept = try #require(tabs.keep(item: tabs.workspace.items[0].id))
        let pinned = try #require(tabs.pin(item: tabs.workspace.items[0].id, show: false))
        _ = tabs.itemProvider(for: .entry(pinned))
        #expect(!tabs.canDrop(onEntry: kept, action: .split(.right)))
        _ = tabs.itemProvider(for: .entry(kept))
        #expect(!tabs.canDrop(onEntry: kept, action: .split(.right)))
    }
}
