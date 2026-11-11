import Foundation
import SunsetPane
import Testing

@testable import SunsetShell

@MainActor @Suite("A window and the Favorites") struct TabsFavoritesTests {
    /// A window with `count` tabs, the last selected.
    private func window(_ count: Int, favorites: FavoritesModel = FavoritesModel()) -> TabsHarness {
        let harness = TabsHarness(favorites: favorites)
        for _ in 0 ..< count { harness.tabs.newTab() }
        return harness
    }

    @Test func `keeping a tab moves it, still running, into the Favorites, and the window shows it there`() throws {
        let harness = window(2)
        let item = harness.tabs.workspace.items[1]
        let content = try #require(harness.content(item.focused))
        harness.tabs.keep(item: item.id)
        let entry = try #require(harness.tabs.favorites.favorites.entries.first)
        #expect(harness.tabs.workspace.count == 1 && entry.isOpen && harness.tabs.workspace.selectedEntry == entry.id)
        #expect(harness.tabs.shownItem?.panes == item.panes && harness.tabs.content(item.focused) === content)
        #expect(!content.stopped && content.visible && content.focused)
        #expect(
            !harness.tabs.isSelected(harness.tabs.workspace.items[0].id),
            "the window's own tab is behind the entry"
        )
    }

    @Test func `unloading stops the entry and keeps it, and the window shows its own tab again`() throws {
        let harness = window(2)
        let item = harness.tabs.workspace.items[1]
        let content = try #require(harness.content(item.focused))
        harness.tabs.keep(item: item.id)
        let id = try #require(harness.tabs.workspace.selectedEntry)
        harness.tabs.unload(entry: id)
        #expect(content.stopped && harness.tabs.favorites.favorites.entry(id)?.isOpen == false)
        #expect(
            harness.tabs.workspace.selectedEntry == nil && harness.tabs.isSelected(harness.tabs.workspace.items[0].id)
        )
    }

    @Test func `an entry that is not open opens from where it was kept when it is selected`() throws {
        let harness = window(1)
        harness.tabs.keep(item: harness.tabs.workspace.items[0].id)
        let id = try #require(harness.tabs.workspace.selectedEntry)
        harness.tabs.unload(entry: id)
        let before = harness.made.count
        harness.tabs.select(entry: id)
        #expect(harness.made.count == before + 1 && harness.tabs.favorites.favorites.entry(id)?.isOpen == true)
        #expect(harness.tabs.workspace.selectedEntry == id && harness.tabs.shownPane != nil)
    }

    @Test func `closing the last tab leaves the window open while there are Favorites, with nothing shown`() throws {
        let harness = window(2)
        harness.tabs.keep(item: harness.tabs.workspace.items[1].id)
        let id = try #require(harness.tabs.workspace.selectedEntry)
        harness.tabs.unload(entry: id)
        harness.tabs.close(item: harness.tabs.workspace.items[0].id)
        #expect(harness.tabs.workspace.isEmpty && !harness.emptied && harness.tabs.shownItem == nil)
        harness.tabs.delete(entry: id)
        #expect(harness.emptied, "with no Favorites left, the window goes")
    }

    @Test func `Cmd-W in a kept entry unloads it with its last pane, asking first when something runs`() throws {
        let harness = window(2)
        harness.tabs.keep(item: harness.tabs.workspace.items[1].id)
        let id = try #require(harness.tabs.workspace.selectedEntry)
        let content = try #require(harness.tabs.shownPane.flatMap(harness.content))
        content.closeWarning = "make is running"
        harness.tabs.closeSelected()
        #expect(!content.stopped)
        harness.tabs.closeSelected()
        #expect(content.stopped && harness.tabs.favorites.favorites.entry(id)?.isOpen == false)
        #expect(harness.tabs.favorites.favorites.count == 1 && harness.tabs.workspace.selectedEntry == nil)
    }

    @Test func `a split in a kept entry stays in the entry`() throws {
        let harness = window(2)
        harness.tabs.keep(item: harness.tabs.workspace.items[1].id)
        harness.tabs.newSplit(.right)
        #expect(harness.tabs.shownItem?.panes.count == 2 && harness.tabs.workspace.allPanes.count == 1)
        let panes = try #require(harness.tabs.shownItem?.panes)
        #expect(panes.allSatisfy { harness.tabs.favorites.contents[$0] != nil })
    }

    @Test func `an entry shown in another window leaves the first one, which shows its own tab`() throws {
        let favorites = FavoritesModel()
        let first = window(2, favorites: favorites)
        let second = window(1, favorites: favorites)
        first.tabs.keep(item: first.tabs.workspace.items[1].id)
        let id = try #require(first.tabs.workspace.selectedEntry)
        second.tabs.select(entry: id)
        #expect(second.tabs.workspace.selectedEntry == id && first.tabs.workspace.selectedEntry == nil)
        #expect(first.tabs.shownItem?.id == first.tabs.workspace.items[0].id)
        #expect(second.tabs.content(try #require(second.tabs.shownPane)) != nil)
    }

    @Test func `Cmd-1 to 9 and Next count the open entries first, then the tabs, and never what is not open`() throws {
        let harness = window(2)
        let tabs = harness.tabs.workspace.items.map(\.id)
        harness.tabs.keep(item: tabs[0])
        let open = try #require(harness.tabs.workspace.selectedEntry)
        harness.tabs.select(index: 1)
        harness.tabs.keep(item: tabs[1])
        let closed = try #require(harness.tabs.workspace.selectedEntry)
        harness.tabs.unload(entry: closed)
        harness.tabs.newTab()
        harness.tabs.select(index: 0)
        #expect(harness.tabs.workspace.selectedEntry == open)
        harness.tabs.selectNext()
        #expect(harness.tabs.workspace.selectedEntry == nil && harness.tabs.workspace.selectedIndex == 0)
        harness.tabs.selectNext()
        #expect(harness.tabs.workspace.selectedEntry == open, "round to the first stop; the closed entry is skipped")
        harness.tabs.selectPrevious()
        #expect(harness.tabs.workspace.selectedEntry == nil)
    }

    @Test func `a new tab while an entry is shown goes after the window's own selected tab`() throws {
        let harness = window(3)
        let tabs = harness.tabs.workspace.items.map(\.id)
        harness.tabs.select(item: tabs[0])
        harness.tabs.keep(item: tabs[2])
        harness.tabs.newTab()
        #expect(harness.tabs.workspace.items.map(\.id).firstIndex(of: tabs[0]) == 0)
        #expect(harness.tabs.workspace.selectedIndex == 1 && harness.tabs.workspace.selectedEntry == nil)
    }

    @Test func `removing from the Favorites gives the entry back as a running tab after the selected one`() throws {
        let harness = window(2)
        let item = harness.tabs.workspace.items[1]
        let content = try #require(harness.content(item.focused))
        harness.tabs.keep(item: item.id)
        let id = try #require(harness.tabs.workspace.selectedEntry)
        harness.tabs.release(entry: id)
        #expect(harness.tabs.favorites.isEmpty && harness.tabs.workspace.count == 2)
        #expect(harness.tabs.contents[item.focused] === content && !content.stopped)
        #expect(harness.tabs.workspace.selectedItem?.panes == item.panes && harness.tabs.workspace.selectedEntry == nil)
    }

    @Test func `a pane of an entry whose program ends closes; the last one unloads the entry`() throws {
        let harness = window(2)
        harness.tabs.keep(item: harness.tabs.workspace.items[1].id)
        let id = try #require(harness.tabs.workspace.selectedEntry)
        try #require(harness.tabs.shownPane.flatMap(harness.content)).onExit()
        #expect(
            harness.tabs.favorites.favorites.entry(id)?.isOpen == false && harness.tabs.workspace.selectedEntry == nil
        )
    }

    @Test func `Set Home to Current makes what the entry is now its start, and the session saves its content`() throws {
        let harness = window(2)
        harness.tabs.keep(item: harness.tabs.workspace.items[1].id)
        let id = try #require(harness.tabs.workspace.selectedEntry)
        harness.tabs.newSplit(.bottom)
        let content = try #require(harness.tabs.shownPane.flatMap(harness.content))
        content.descriptor = .terminal(directory: "/moved")
        harness.tabs.favorites.setHomeToCurrent(id)
        let home = try #require(harness.tabs.favorites.favorites.entry(id)?.home)
        #expect(home.layout.panes.count == 2 && home.contents.values.contains(.terminal(directory: "/moved")))
        #expect(harness.tabs.favorites.saved().contents.values.contains(.terminal(directory: "/moved")))
    }

    @Test func `a window that showed an entry comes back showing it, its content made then`() throws {
        var kept = Favorites()
        let pane = PaneID()
        let added = kept.addEntry(home: Favorites.Home(layout: .pane(pane), focused: pane))
        let id = try #require(added)
        kept.open(id)
        let favorites = FavoritesModel()
        favorites.restore(
            SavedFavorites(favorites: kept, contents: [pane: .terminal(directory: "/k")]),
            reopening: true
        )
        var workspace = Workspace()
        workspace.select(entry: id)
        let harness = TabsHarness(favorites: favorites)
        harness.tabs.restore(SavedWindow(workspace: workspace))
        #expect(
            harness.tabs.workspace.selectedEntry == id
                && harness.content(pane)?.descriptor == .terminal(directory: "/k")
        )
    }
}
