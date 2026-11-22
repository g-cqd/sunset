import SunsetPane
import Testing

@testable import SunsetShell
@testable import SunsetShellModel

/// "Drag and drop of pinned, favorites and tabs does not work reliably"; "all tabs should be movable to all sections […]
/// split dragging a tab from a split tab container should drag the container itself to whatever section. current drag and
/// drop fails to reorder pinned tabs, and does not also work for favorites, all tabs and all kinds should be movable across
/// all sections, with the exceptions of folders that can only be moved within favorites".
@MainActor
@Suite("Dragging between the sidebar's sections")
struct TabsSectionDropTests {
    /// A window with a Pinned grid: `pinned` tiles, `kept` favourites and `today` tabs, made in that order.
    private func window(pinned: Int = 0, kept: Int = 0, today: Int = 0) throws -> TabsHarness {
        let harness = TabsHarness()
        harness.tabs.pinned = FavoritesModel()
        for _ in 0 ..< pinned {
            harness.tabs.newTab()
            let id = try #require(harness.tabs.workspace.selectedID)
            _ = try #require(harness.tabs.pin(item: id, show: false))
        }
        for _ in 0 ..< kept {
            harness.tabs.newTab()
            let id = try #require(harness.tabs.workspace.selectedID)
            _ = try #require(harness.tabs.keep(item: id, show: false))
        }
        for _ in 0 ..< today { harness.tabs.newTab() }
        return harness
    }

    private func grid(_ harness: TabsHarness) -> [Favorites.NodeID] {
        harness.tabs.pinnedEntries.map(\.id)
    }
    private func kept(_ harness: TabsHarness) -> [Favorites.NodeID] {
        harness.tabs.favorites.favorites.entries.map(\.id)
    }
    private func today(_ harness: TabsHarness) -> [Workspace.ItemID] {
        harness.tabs.workspace.items.map(\.id)
    }

    // MARK: The Pinned grid

    @Test func `a tile dragged within the grid is put where it is dropped, either way`() throws {
        let harness = try window(pinned: 3)
        let tiles = grid(harness)
        _ = harness.tabs.itemProvider(for: .entry(tiles[0]))
        #expect(harness.tabs.canDropDragged(in: .pinned(at: 3)))
        #expect(harness.tabs.dropDragged(in: .pinned(at: 3)))
        #expect(grid(harness) == [tiles[1], tiles[2], tiles[0]])
        _ = harness.tabs.itemProvider(for: .entry(tiles[0]))
        #expect(harness.tabs.dropDragged(in: .pinned(at: 0)))
        #expect(grid(harness) == tiles)
        #expect(harness.tabs.dragged == nil)
    }

    @Test func `a tab and a favourite dropped on the grid are pinned at that place`() throws {
        let harness = try window(pinned: 2, kept: 1, today: 1)
        let tiles = grid(harness)
        let tab = try #require(today(harness).last)
        _ = harness.tabs.itemProvider(for: .item(tab))
        #expect(harness.tabs.dropDragged(in: .pinned(at: 1)))
        #expect(grid(harness).count == 3 && grid(harness)[0] == tiles[0] && grid(harness)[2] == tiles[1])
        #expect(!today(harness).contains(tab))
        let favourite = try #require(kept(harness).first)
        _ = harness.tabs.itemProvider(for: .entry(favourite))
        #expect(harness.tabs.dropDragged(in: .pinned(at: 0)))
        #expect(grid(harness).first == favourite && kept(harness).isEmpty)
    }

    @Test func `a tile dropped among the Favorites becomes a favourite at that place, still running`() throws {
        let harness = try window(pinned: 1, kept: 2)
        let tile = try #require(grid(harness).first)
        harness.tabs.select(entry: tile)
        let content = try #require(harness.made.first)
        let favourites = kept(harness)
        _ = harness.tabs.itemProvider(for: .entry(tile))
        #expect(harness.tabs.canDropDragged(in: .favorites(in: nil, at: 1)))
        #expect(harness.tabs.dropDragged(in: .favorites(in: nil, at: 1)))
        #expect(kept(harness) == [favourites[0], tile, favourites[1]] && grid(harness).isEmpty)
        #expect(!content.stopped)
    }

    @Test func `a tile dropped on a favourite's row, or on the Favorites' line, becomes a favourite`() throws {
        let harness = try window(pinned: 2, kept: 1)
        let tiles = grid(harness)
        let favourite = try #require(kept(harness).first)
        _ = harness.tabs.itemProvider(for: .entry(tiles[0]))
        #expect(harness.tabs.canDrop(onEntry: favourite))
        #expect(harness.tabs.dropDragged(onEntry: favourite, after: false))
        #expect(kept(harness) == [tiles[0], favourite])
        _ = harness.tabs.itemProvider(for: .entry(tiles[1]))
        #expect(harness.tabs.canDropOnFavoritesLine)
        #expect(harness.tabs.dropDraggedOnFavoritesLine())
        #expect(kept(harness) == [tiles[0], favourite, tiles[1]] && grid(harness).isEmpty)
    }

    @Test func `a tile dropped among Today's tabs is a tab again, at that place`() throws {
        let harness = try window(pinned: 1, today: 2)
        let tile = try #require(grid(harness).first)
        let tabs = today(harness)
        _ = harness.tabs.itemProvider(for: .entry(tile))
        #expect(harness.tabs.canDrop(onto: tabs[1], action: .moveBefore))
        #expect(harness.tabs.dropDragged(onto: tabs[1], action: .moveBefore))
        #expect(today(harness).count == 3 && today(harness)[0] == tabs[0] && today(harness)[2] == tabs[1])
        #expect(grid(harness).isEmpty)
    }

    // MARK: Favorites and Today

    @Test func `a favourite dropped among Today's tabs is a tab again; dropped in the Favorites it moves`() throws {
        let harness = try window(kept: 3, today: 1)
        let favourites = kept(harness)
        _ = harness.tabs.itemProvider(for: .entry(favourites[2]))
        #expect(harness.tabs.dropDragged(in: .favorites(in: nil, at: 0)))
        #expect(kept(harness) == [favourites[2], favourites[0], favourites[1]])
        _ = harness.tabs.itemProvider(for: .entry(favourites[0]))
        #expect(harness.tabs.dropDragged(in: .today(at: 0)))
        #expect(today(harness).count == 2 && kept(harness) == [favourites[2], favourites[1]])
    }

    @Test func `a tab dropped in Today's tabs moves there; anywhere in the Favorites it is kept there`() throws {
        let harness = try window(kept: 1, today: 3)
        let tabs = today(harness)
        _ = harness.tabs.itemProvider(for: .item(tabs[0]))
        #expect(harness.tabs.dropDragged(in: .today(at: 3)))
        #expect(today(harness) == [tabs[1], tabs[2], tabs[0]])
        _ = harness.tabs.itemProvider(for: .item(tabs[1]))
        #expect(harness.tabs.dropDragged(in: .favorites(in: nil, at: 0)))
        #expect(kept(harness).count == 2 && today(harness) == [tabs[2], tabs[0]])
    }

    // MARK: Splits

    @Test func `a pane dragged from a split's row carries the split to the grid and to the Favorites`() throws {
        let harness = try window(today: 2)
        harness.tabs.split(.right, with: FakeContent(), beside: harness.tabs.selectedContent ?? FakeContent())
        let split = try #require(harness.tabs.workspace.selectedItem)
        #expect(split.isSplit)
        _ = harness.tabs.itemProvider(for: .pane(split.panes[1]))
        #expect(harness.tabs.canDropDragged(in: .pinned(at: nil)))
        #expect(harness.tabs.dropDragged(in: .pinned(at: nil)))
        let tile = try #require(harness.tabs.pinnedEntries.first)
        #expect(tile.open?.panes.count == 2, "the whole split, not the pane")
        harness.tabs.newTab()
        harness.tabs.split(.right, with: FakeContent(), beside: harness.tabs.selectedContent ?? FakeContent())
        let other = try #require(harness.tabs.workspace.selectedItem)
        _ = harness.tabs.itemProvider(for: .pane(other.panes[0]))
        #expect(harness.tabs.dropDragged(in: .favorites(in: nil, at: nil)))
        #expect(harness.tabs.favorites.favorites.entries.first?.open?.panes.count == 2)
    }

    @Test func `a pane dragged from a split's row onto Today's tabs moves the whole split`() throws {
        let harness = try window(today: 3)
        harness.tabs.split(.right, with: FakeContent(), beside: harness.tabs.selectedContent ?? FakeContent())
        let tabs = today(harness)
        let split = try #require(harness.tabs.workspace.selectedItem)
        _ = harness.tabs.itemProvider(for: .pane(split.panes[0]))
        #expect(harness.tabs.canDrop(onto: tabs[0], action: .moveBefore))
        #expect(harness.tabs.dropDragged(onto: tabs[0], action: .moveBefore))
        #expect(today(harness) == [split.id, tabs[0], tabs[1]])
        #expect(harness.tabs.workspace.items[0].panes.count == 2)
    }

    // MARK: Folders

    @Test func `a folder moves within the Favorites only`() throws {
        let harness = try window(pinned: 1, kept: 1, today: 1)
        harness.tabs.newFolder()
        harness.tabs.renamingRow = nil
        let folder = try #require(harness.tabs.favorites.favorites.nodes.last?.id)
        _ = harness.tabs.itemProvider(for: .entry(folder))
        #expect(!harness.tabs.canDropDragged(in: .pinned(at: 0)))
        #expect(!harness.tabs.dropDragged(in: .pinned(at: 0)))
        let tab = try #require(today(harness).first)
        #expect(!harness.tabs.canDrop(onto: tab, action: .moveBefore))
        #expect(!harness.tabs.canDropDragged(in: .today(at: 0)))
        #expect(harness.tabs.canDropDragged(in: .favorites(in: nil, at: 0)))
        #expect(harness.tabs.dropDragged(in: .favorites(in: nil, at: 0)))
        #expect(harness.tabs.favorites.favorites.nodes.first?.id == folder)
        #expect(harness.tabs.pinnedEntries.count == 1 && today(harness) == [tab])
    }

    @Test func `a tile can go into a folder of the Favorites`() throws {
        let harness = try window(pinned: 1)
        harness.tabs.newFolder()
        harness.tabs.renamingRow = nil
        let folder = try #require(harness.tabs.favorites.favorites.nodes.last?.id)
        let tile = try #require(grid(harness).first)
        _ = harness.tabs.itemProvider(for: .entry(tile))
        #expect(harness.tabs.canDrop(intoFolder: folder) && harness.tabs.dropDragged(intoFolder: folder))
        #expect(harness.tabs.favorites.favorites.location(of: tile)?.parent == folder && grid(harness).isEmpty)
    }
}
