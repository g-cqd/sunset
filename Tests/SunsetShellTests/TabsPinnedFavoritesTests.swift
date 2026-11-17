import Foundation
import SunsetPane
import Testing

@testable import SunsetShell

/// An entry between the Favorites and the Pinned grid (ADR-0054; the owner, 2026-11-17: "the context menus of tabs and
/// sidebar don't contain all features related to pinning and marking as favorites and i fail to set an already
/// favorites tab as a pinned tab").
@MainActor
@Suite("A favourite and the Pinned grid")
struct TabsPinnedFavoritesTests {
    private func window(_ pinned: FavoritesModel, made: MadeContents) -> TabsModel {
        let tabs = TabsModel()
        tabs.makeContent = { descriptor in
            let content = FakeContent(descriptor)
            made.all.append(content)
            return content
        }
        tabs.pinned = pinned
        return tabs
    }

    @Test func `a favourite is pinned as it is: its name, icon and command, still running, still shown where it was`()
        throws
    {
        let (pinned, made) = (FavoritesModel(), MadeContents())
        let tabs = window(pinned, made: made)
        tabs.favorites.sealer = TestSealer()
        tabs.newTab(.terminal(directory: "/kept"))
        let tab = try #require(tabs.workspace.selectedID)
        let entry = try #require(tabs.keep(item: tab))
        tabs.rename(.node(entry), to: "Logs")
        tabs.setIcon(.emoji("\u{1F4DC}"), for: .node(entry))
        tabs.favorites.setCommand("tail -f log", for: entry)
        #expect(tabs.canPin(.node(entry)) && tabs.pin(entry: entry))
        #expect(tabs.favorites.isEmpty && pinned.favorites.entries.map(\.id) == [entry], "the same entry, in the grid")
        let moved = try #require(pinned.favorites.entry(entry))
        #expect(moved.title == "Logs" && moved.icon == .emoji("\u{1F4DC}") && moved.command == "tail -f log")
        #expect(moved.isOpen && !made.all[0].stopped && pinned.contents.count == 1 && tabs.favorites.contents.isEmpty)
        #expect(tabs.shownEntry?.id == entry && tabs.showsLive && made.all[0].visible, "still shown, still drawn here")
        // What ends by itself now closes in the grid.
        made.all[0].onExit()
        #expect(pinned.favorites.entry(entry)?.isOpen == false)
        #expect(!tabs.pin(entry: entry), "already pinned")
    }

    @Test
    func `a favourite that is not open, or in a folder, is pinned too; a folder is not; with no room nothing moves`()
        throws
    {
        let (pinned, made) = (FavoritesModel(), MadeContents())
        let tabs = window(pinned, made: made)
        tabs.newTab(.terminal(directory: "/a"))
        let first = try #require(tabs.workspace.selectedID)
        let entry = try #require(tabs.keep(item: first))
        tabs.group([.node(entry)])
        let folder = try #require(tabs.favorites.favorites.location(of: entry)?.parent)
        tabs.unload(entry: entry)
        #expect(!tabs.canPin(.node(folder)) && tabs.canPin(.node(entry)))
        #expect(tabs.pin(entry: entry) && pinned.favorites.entry(entry)?.isOpen == false)
        #expect(tabs.favorites.favorites.folder(folder)?.children.isEmpty == true, "the folder stays, empty")
        #expect(pinned.favorites.entry(entry)?.home.contents.values.first?.directory == "/a")
        for _ in 0 ..< TabsModel.pinnedLimit - 1 {
            tabs.newTab()
            let tab = try #require(tabs.workspace.selectedID)
            _ = try #require(tabs.pin(item: tab, show: false))
        }
        tabs.newTab()
        let extra = try #require(tabs.workspace.selectedID)
        let kept = try #require(tabs.keep(item: extra))
        #expect(!tabs.canPin(.node(kept)) && !tabs.pin(entry: kept) && tabs.favorites.favorites.entry(kept) != nil)
    }

    @Test func `a pinned entry goes to the Favorites as it is, and back to a tab from there`() throws {
        let (pinned, made) = (FavoritesModel(), MadeContents())
        let tabs = window(pinned, made: made)
        tabs.newTab()
        let tab = try #require(tabs.workspace.selectedID)
        let entry = try #require(tabs.pin(item: tab))
        tabs.rename(.node(entry), to: "Mail")
        #expect(tabs.favorite(pinned: entry))
        #expect(pinned.favorites.isEmpty && tabs.favorites.favorites.entry(entry)?.title == "Mail")
        #expect(tabs.favorites.favorites.entry(entry)?.isOpen == true && !made.all[0].stopped && tabs.showsLive)
        #expect(!tabs.favorite(pinned: entry), "it is a favourite already")
        tabs.release(entry: entry)
        #expect(tabs.favorites.isEmpty && tabs.workspace.count == 1 && !made.all[0].stopped)
    }

    @Test func `the rows selected, or dragged, are pinned together: tabs and favourites, while there is room`() throws {
        let (pinned, made) = (FavoritesModel(), MadeContents())
        let tabs = window(pinned, made: made)
        tabs.newTab()
        let keeping = try #require(tabs.workspace.selectedID)
        let kept = try #require(tabs.keep(item: keeping))
        tabs.newTab()
        let tab = try #require(tabs.workspace.selectedID)
        #expect(tabs.pin([.node(kept), .tab(tab)]) == 2)
        #expect(pinned.favorites.entries.count == 2 && tabs.favorites.isEmpty && tabs.workspace.isEmpty)
        // Dragged onto the grid: one tab's row (found 2026-11-17: a single row dragged there was never pinned).
        tabs.newTab()
        let single = try #require(tabs.workspace.selectedID)
        _ = tabs.itemProvider(for: .item(single))
        #expect(
            tabs.canPinDragged && tabs.pinDragged() && tabs.workspace.isEmpty && pinned.favorites.entries.count == 3
        )
        // And a favourite's row.
        tabs.newTab()
        let another = try #require(tabs.workspace.selectedID)
        let other = try #require(tabs.keep(item: another))
        _ = tabs.itemProvider(for: .entry(other))
        #expect(tabs.canPinDragged && tabs.pinDragged() && pinned.favorites.entry(other) != nil)
    }

    /// A tile dragged out of the grid: onto the Favorites it becomes a favourite there, in the folder and at the place it
    /// was dropped.
    @Test func `a pinned entry dropped among the Favorites goes there, in the folder and at the place it was dropped`()
        throws
    {
        let (pinned, made) = (FavoritesModel(), MadeContents())
        let tabs = window(pinned, made: made)
        tabs.newTab()
        let first = try #require(tabs.workspace.selectedID)
        let kept = try #require(tabs.keep(item: first))
        tabs.group([.node(kept)])
        let folder = try #require(tabs.favorites.favorites.location(of: kept)?.parent)
        tabs.newTab()
        let second = try #require(tabs.workspace.selectedID)
        let entry = try #require(tabs.pin(item: second))
        tabs.move([.node(entry)], into: folder, at: 0)
        #expect(pinned.favorites.isEmpty)
        #expect(tabs.favorites.favorites.folder(folder)?.children.map(\.id) == [entry, kept])
        #expect(tabs.favorites.favorites.entry(entry)?.isOpen == true && !made.all[1].stopped)
    }

    @Test func `resetting an entry in which something runs asks first, as unloading it does`() throws {
        let (pinned, made) = (FavoritesModel(), MadeContents())
        let tabs = window(pinned, made: made)
        tabs.newTab()
        let tab = try #require(tabs.workspace.selectedID)
        let entry = try #require(tabs.pin(item: tab))
        made.all[0].closeWarning = "make is running"
        tabs.reset(entry: entry)
        let open = try #require(pinned.favorites.entry(entry)?.open)
        #expect(!made.all[0].stopped && tabs.isCloseArmed(open.id), "asked: the tile is marked, nothing stopped")
        tabs.reset(entry: entry)
        #expect(made.all[0].stopped && made.all.count == 2 && pinned.favorites.entry(entry)?.isOpen == true)
    }
}
