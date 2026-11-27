import Foundation
import SunsetPane
import Testing

@testable import SunsetShell
@testable import SunsetShellModel

/// Dropping onto the middle of a Favorite row or a Pinned tile splits in place inside the Favorite or Pinned entry,
/// never releasing the Favorite or Pinned entry into Today's tabs. Dropping on the outer quarters reorders or keeps/pins
/// before or after it.
@MainActor
@Suite("A tab or entry dropped on a Favorite or Pinned entry")
struct FavoriteDropSplitTests {
    private func window() -> TabsModel {
        let tabs = TabsModel()
        tabs.makeContent = { FakeContent($0) }
        tabs.pinned = FavoritesModel()
        return tabs
    }

    @Test func `on the middle of a favorite's row, a tab splits in place inside Favorites without moving to Today`()
        throws
    {
        let tabs = window()
        tabs.newTab()
        tabs.newTab()
        tabs.newTab()
        let kept = try #require(tabs.keep(item: tabs.workspace.items[0].id))
        let dragged = tabs.workspace.items[0].id
        _ = tabs.itemProvider(for: .item(dragged))
        #expect(tabs.canDrop(onEntry: kept, action: .split(.left)))
        #expect(tabs.dropDragged(onEntry: kept, action: .split(.left)))
        let open = try #require(tabs.favorites.favorites.entry(kept)?.open)
        #expect(open.panes.count == 2, "split inside the favorite")
        #expect(tabs.shownEntry?.id == kept)
        #expect(tabs.workspace.count == 1, "dragged tab joined the favorite; Today gained nothing")
        #expect(!tabs.workspace.items.contains { $0.id == dragged })
    }

    @Test func `on the middle of a pinned tile, a tab splits in place inside Pinned without moving to Today`() throws {
        let tabs = window()
        tabs.newTab()
        tabs.newTab()
        tabs.newTab()
        let pinned = try #require(tabs.pin(item: tabs.workspace.items[0].id, show: false))
        let dragged = tabs.workspace.items[0].id
        _ = tabs.itemProvider(for: .item(dragged))
        #expect(tabs.canDrop(onEntry: pinned, action: .split(.right)))
        #expect(tabs.dropDragged(onEntry: pinned, action: .split(.right)))
        let open = try #require(tabs.pinned?.favorites.entry(pinned)?.open)
        #expect(open.panes.count == 2, "split inside the pinned entry")
        #expect(tabs.shownEntry?.id == pinned)
        #expect(tabs.workspace.count == 1, "Today gained nothing")
    }

    @Test func `a pane of a split dropped on a favorite or pinned entry splits in place too`() throws {
        let tabs = window()
        tabs.newTab()
        tabs.newTab()
        tabs.newSplit(.right)
        let kept = try #require(tabs.keep(item: tabs.workspace.items[0].id, show: false))
        let pane = try #require(tabs.workspace.items.first { $0.panes.count == 2 }?.focused)
        _ = tabs.itemProvider(for: .pane(pane))
        #expect(tabs.dropDragged(onEntry: kept, action: .split(.right)))
        let open = try #require(tabs.favorites.favorites.entry(kept)?.open)
        #expect(open.panes.contains(pane) && open.panes.count == 2)
        #expect(tabs.workspace.count == 1 && tabs.workspace.items[0].panes.count == 1)
    }

    @Test func `dropping onto the pane area while showing a favorite or pinned entry splits in place`() throws {
        let tabs = window()
        tabs.newTab()
        tabs.newTab()
        let pinned = try #require(tabs.pin(item: tabs.workspace.items[0].id, show: true))
        let targetPane = try #require(tabs.shownPane)
        let dragged = tabs.workspace.items[0].id
        _ = tabs.itemProvider(for: .item(dragged))
        #expect(tabs.canDrop(onto: targetPane))
        #expect(tabs.dropDragged(onto: targetPane, edge: .right))
        #expect(tabs.pinned?.favorites.entry(pinned)?.open?.panes.count == 2)
        #expect(tabs.workspace.isEmpty, "never moved to Today")
    }

    @Test func `a favorite or pinned entry dropped on another splits in place; never on itself`() throws {
        let tabs = window()
        tabs.newTab()
        tabs.newTab()
        tabs.newTab()
        let kept = try #require(tabs.keep(item: tabs.workspace.items[0].id, show: false))
        let pinned = try #require(tabs.pin(item: tabs.workspace.items[0].id, show: false))
        _ = tabs.itemProvider(for: .entry(kept))
        #expect(!tabs.canDrop(onEntry: kept, action: .split(.right)))
        _ = tabs.itemProvider(for: .entry(pinned))
        #expect(!tabs.canDrop(onEntry: pinned, action: .split(.right)))
        #expect(tabs.canDrop(onEntry: kept, action: .split(.right)))
        #expect(tabs.dropDragged(onEntry: kept, action: .split(.right)))
        #expect(tabs.favorites.favorites.entry(kept)?.open?.panes.count == 2)
        #expect(tabs.pinnedEntries.isEmpty)
        #expect(tabs.workspace.count == 1, "Today untouched")
    }

    @Test func `on outer quarters, a tab goes before or after a favorite or pinned tile without splitting`() throws {
        let tabs = window()
        tabs.newTab()
        tabs.newTab()
        tabs.newTab()
        let kept = try #require(tabs.keep(item: tabs.workspace.items[0].id, show: false))
        _ = tabs.itemProvider(for: .item(tabs.workspace.items[0].id))
        #expect(tabs.canDrop(onEntry: kept, action: .moveAfter))
        #expect(tabs.dropDragged(onEntry: kept, action: .moveAfter))
        #expect(tabs.favorites.favorites.entries.count == 2)

        let pinned = try #require(tabs.pin(item: tabs.workspace.items[0].id, show: false))
        _ = tabs.itemProvider(for: .entry(tabs.favorites.favorites.entries[1].id))
        #expect(tabs.canDrop(onEntry: pinned, action: .moveBefore))
        #expect(tabs.dropDragged(onEntry: pinned, action: .moveBefore))
        #expect(tabs.pinnedEntries.count == 2 && tabs.pinnedEntries[1].id == pinned)
    }
}
