import Foundation
import Testing

@testable import SunsetPane

@Suite("Favorites: kept entries") struct FavoritesEntryTests {
    @Test func `keeping a tab makes an open entry that starts from what the tab was, with its name and icon`() throws {
        var favorites = Favorites()
        var item = FavoritesFixture.item(panes: 2)
        item.customTitle = "server"
        item.customIcon = .emoji("🚀")
        let contents = Dictionary(
            uniqueKeysWithValues: item.panes.map { ($0, PaneDescriptor.terminal(directory: "/srv")) }
        )
        let id = try FavoritesFixture.need(favorites.keep(item, contents: contents))
        let entry = try FavoritesFixture.need(favorites.entry(id))
        #expect(entry.isOpen && entry.open?.panes == item.panes)
        #expect(entry.title == "server" && entry.icon == .emoji("🚀"))
        #expect(entry.open?.customTitle == nil && entry.open?.customIcon == nil)
        #expect(
            entry.home.layout == item.layout && entry.home.focused == item.focused && entry.home.contents == contents
        )
        #expect(favorites.livePanes == item.panes)
        #expect(favorites.entry(containing: item.panes[1])?.id == id)
    }

    @Test func `an entry added closed has no live pane until it is opened, and opens from its home`() throws {
        var favorites = Favorites()
        let home = FavoritesFixture.home("/work")
        let id = try FavoritesFixture.need(favorites.addEntry(home: home, title: "work"))
        #expect(favorites.entry(id)?.isOpen == false && favorites.livePanes.isEmpty)
        let item = try FavoritesFixture.need(favorites.open(id))
        #expect(item.layout == home.layout && item.focused == home.focused)
        #expect(favorites.livePanes == home.layout.panes)
        #expect(favorites.open(id) == item, "opening again gives the same live tab")
    }

    @Test func `unloading stops an entry and keeps it; it opens again from where it was kept`() throws {
        var favorites = Favorites()
        let item = FavoritesFixture.item()
        let id = try FavoritesFixture.need(favorites.keep(item, contents: [item.focused: .terminal(directory: "/a")]))
        let extra = try FavoritesFixture.need(favorites.addPane(beside: item.focused, edge: .right))
        let gone = favorites.unload(id)
        #expect(Set(gone) == [item.focused, extra])
        #expect(favorites.entry(id)?.isOpen == false && favorites.count == 1)
        #expect(favorites.open(id)?.panes == item.panes, "the split made while open is not what it starts from")
        #expect(favorites.unload(Favorites.NodeID()).isEmpty)
    }

    @Test func `removing an entry deletes it and returns its live panes`() throws {
        var favorites = Favorites()
        let item = FavoritesFixture.item()
        let id = try FavoritesFixture.need(favorites.keep(item, contents: [:]))
        #expect(favorites.remove(id) == item.panes && favorites.nodes.isEmpty)
        #expect(favorites.remove(id).isEmpty)
    }

    @Test func `releasing an open entry gives its live tab back with its name, and nothing to start`() throws {
        var favorites = Favorites()
        var item = FavoritesFixture.item()
        item.customTitle = "logs"
        let id = try FavoritesFixture.need(favorites.keep(item, contents: [:]))
        let released = try FavoritesFixture.need(favorites.release(id))
        #expect(released.item.panes == item.panes && released.item.customTitle == "logs" && released.home == nil)
        #expect(favorites.nodes.isEmpty)
    }

    @Test func `releasing a closed entry gives a tab to start from its home`() throws {
        var favorites = Favorites()
        let home = FavoritesFixture.home("/x")
        let id = try FavoritesFixture.need(favorites.addEntry(home: home, title: "x", icon: .symbol("star")))
        let released = try FavoritesFixture.need(favorites.release(id))
        #expect(released.item.layout == home.layout && released.home == home.contents)
        #expect(released.item.customTitle == "x" && released.item.customIcon == .symbol("star"))
        #expect(favorites.release(id) == nil)
    }

    @Test func `an entry is renamed; a blank name gives its content's title back`() throws {
        var favorites = Favorites()
        let id = try FavoritesFixture.need(favorites.addEntry(home: FavoritesFixture.home(), title: "a"))
        favorites.rename(id, to: " b ")
        #expect(favorites.entry(id)?.title == "b")
        favorites.rename(id, to: " ")
        #expect(favorites.entry(id)?.title == nil)
        favorites.setIcon(.emoji("🔥"), for: id)
        #expect(favorites.entry(id)?.icon == .emoji("🔥"))
    }

    @Test func `the panes of an open entry are focused, split, resized and closed; the last pane closing unloads it`()
        throws
    {
        var favorites = Favorites()
        let item = FavoritesFixture.item()
        let id = try FavoritesFixture.need(favorites.keep(item, contents: [:]))
        let second = try FavoritesFixture.need(favorites.addPane(beside: item.focused, edge: .bottom))
        #expect(favorites.entry(id)?.open?.focused == second && favorites.entry(id)?.open?.panes.count == 2)
        favorites.focus(pane: item.focused)
        #expect(favorites.entry(id)?.open?.focused == item.focused)
        favorites.setRatio(0.3, at: [], in: id)
        guard case .split(_, let ratio, _, _) = favorites.entry(id)?.open?.layout else {
            Issue.record("not a split")
            return
        }
        #expect(ratio == 0.3)
        #expect(favorites.close(pane: item.focused) == false)
        #expect(favorites.entry(id)?.open?.panes == [second] && favorites.entry(id)?.open?.focused == second)
        #expect(favorites.close(pane: second) == true, "its only pane: the entry is unloaded")
        #expect(favorites.entry(id)?.isOpen == false && favorites.count == 1)
        #expect(favorites.addPane(beside: PaneID(), edge: .left) == nil && favorites.close(pane: PaneID()) == false)
    }

    @Test func `an entry whose home does not hold together is not added`() {
        var favorites = Favorites()
        let pane = PaneID()
        let stranger = Favorites.Home(layout: .pane(pane), focused: PaneID())
        let twice = Favorites.Home(
            layout: .split(.horizontal, ratio: 0.5, first: .pane(pane), second: .pane(pane)),
            focused: pane
        )
        #expect(favorites.addEntry(home: stranger) == nil && favorites.addEntry(home: twice) == nil)
        #expect(favorites.isEmpty)
    }

    @Test func `nothing is kept inside an entry or an unknown folder`() {
        var favorites = Favorites()
        let entry = favorites.addEntry(home: FavoritesFixture.home(), title: "a")
        #expect(favorites.keep(FavoritesFixture.item(), contents: [:], in: entry) == nil)
        #expect(favorites.addEntry(home: FavoritesFixture.home(), title: "b", in: Favorites.NodeID()) == nil)
        #expect(favorites.count == 1)
    }
}
