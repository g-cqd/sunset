import Foundation
import Testing

@testable import SunsetPane

@Suite("Favorites: folders") struct FavoritesFolderTests {
    @Test func `a folder is added at the top or inside another, where asked, and lives empty`() {
        var favorites = Favorites()
        let work = favorites.addFolder(named: "Work")
        let play = favorites.addFolder(named: "Play", at: 0)
        let inner = favorites.addFolder(named: "Inner", in: work)
        #expect(work != nil && play != nil && inner != nil)
        #expect(FavoritesFixture.shape(favorites.nodes) == "Play[] Work[Inner[]]")
        #expect(favorites.count == 3 && favorites.entries.isEmpty)
        #expect(inner.flatMap { favorites.location(of: $0) } == Favorites.Location(parent: work, index: 0, level: 1))
    }

    @Test func `folders nest to four levels and no deeper`() {
        var favorites = Favorites()
        let chain = FavoritesFixture.chain(5, in: &favorites)
        #expect(chain.count == Favorites.maximumDepth)
        #expect(favorites.addFolder(named: "too deep", in: chain.last) == nil)
        #expect(FavoritesFixture.shape(favorites.nodes) == "1[2[3[4[]]]]")
    }

    @Test func `a folder is not added inside an entry or an unknown node`() {
        var favorites = Favorites()
        let entry = favorites.addEntry(home: FavoritesFixture.home(), title: "a")
        #expect(favorites.addFolder(named: "x", in: entry) == nil)
        #expect(favorites.addFolder(named: "x", in: Favorites.NodeID()) == nil)
        #expect(favorites.count == 1)
    }

    @Test func `a folder is renamed, a blank name changes nothing, and it takes an icon`() throws {
        var favorites = Favorites()
        let id = try FavoritesFixture.need(favorites.addFolder(named: "Work"))
        favorites.rename(id, to: "  Office ")
        #expect(favorites.folder(id)?.name == "Office")
        favorites.rename(id, to: "   ")
        #expect(favorites.folder(id)?.name == "Office")
        favorites.setIcon(.symbol("briefcase"), for: id)
        #expect(favorites.folder(id)?.icon == .symbol("briefcase"))
        favorites.setIcon(nil, for: id)
        #expect(favorites.folder(id)?.icon == nil)
    }

    @Test func `a folder starts expanded and its collapsed state is kept`() throws {
        var favorites = Favorites()
        let id = try FavoritesFixture.need(favorites.addFolder(named: "Work"))
        #expect(favorites.folder(id)?.isCollapsed == false)
        favorites.setCollapsed(true, for: id)
        #expect(favorites.folder(id)?.isCollapsed == true)
    }

    @Test func `ungrouping removes the folder and leaves its content in its place`() throws {
        var favorites = Favorites()
        favorites.addEntry(home: FavoritesFixture.home(), title: "a")
        let folder = try FavoritesFixture.need(favorites.addFolder(named: "F"))
        favorites.addEntry(home: FavoritesFixture.home(), title: "b", in: folder)
        favorites.addFolder(named: "G", in: folder)
        favorites.addEntry(home: FavoritesFixture.home(), title: "c")
        favorites.ungroup(folder)
        #expect(FavoritesFixture.shape(favorites.nodes) == "a b G[] c")
    }

    @Test func `grouping puts nodes in a new folder where the first of them was, in their order`() throws {
        var favorites = Favorites()
        let first = try FavoritesFixture.need(favorites.addEntry(home: FavoritesFixture.home(), title: "a"))
        favorites.addEntry(home: FavoritesFixture.home(), title: "b")
        let third = try FavoritesFixture.need(favorites.addEntry(home: FavoritesFixture.home(), title: "c"))
        let folder = favorites.group([third, first], named: "New Folder")
        #expect(folder != nil)
        #expect(FavoritesFixture.shape(favorites.nodes) == "New Folder[a c] b")
    }

    @Test func `grouping at the deepest level is refused and changes nothing`() throws {
        var favorites = Favorites()
        let chain = FavoritesFixture.chain(4, in: &favorites)
        let entry = try FavoritesFixture.need(
            favorites.addEntry(home: FavoritesFixture.home(), title: "a", in: chain.last)
        )
        #expect(favorites.group([entry], named: "x") == nil)
        #expect(FavoritesFixture.shape(favorites.nodes) == "1[2[3[4[a]]]]")
    }

    @Test func `removing a folder removes what is inside and returns the panes that were live`() throws {
        var favorites = Favorites()
        let folder = try FavoritesFixture.need(favorites.addFolder(named: "F"))
        let item = FavoritesFixture.item(panes: 2)
        favorites.keep(item, contents: [:], in: folder)
        favorites.addEntry(home: FavoritesFixture.home(), title: "closed", in: folder)
        let gone = favorites.remove(folder)
        #expect(gone == item.panes && favorites.nodes.isEmpty)
    }
}
