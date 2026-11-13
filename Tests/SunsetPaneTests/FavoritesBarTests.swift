import Testing

@testable import SunsetPane

@Suite("Favorites in the built-in tab bar") struct FavoritesBarTests {
    @Test func `top-level open entries, and each folder followed by the open entries it holds at any depth`() throws {
        var favorites = Favorites()
        let loose = try FavoritesFixture.need(favorites.keep(FavoritesFixture.item(), contents: [:]))
        favorites.addEntry(home: FavoritesFixture.home(), title: "closed")
        let folder = try FavoritesFixture.need(favorites.addFolder(named: "F"))
        let inner = try FavoritesFixture.need(favorites.addFolder(named: "G", in: folder))
        let a = try FavoritesFixture.need(favorites.keep(FavoritesFixture.item(), contents: [:], in: folder))
        let b = try FavoritesFixture.need(favorites.keep(FavoritesFixture.item(), contents: [:], in: inner))
        favorites.addFolder(named: "empty")
        #expect(
            favorites.barItems(selected: nil) == [.entry(loose), .folder(folder, openCount: 2), .entry(b), .entry(a)],
            "the order of the tree: G (holding b) was made before a"
        )
        favorites.setCollapsed(true, for: folder)
        #expect(favorites.barItems(selected: nil) == [.entry(loose), .folder(folder, openCount: 2)])
        #expect(favorites.barItems(selected: b) == [.entry(loose), .folder(folder, openCount: 2), .entry(b)])
    }

    @Test func `pinned: every entry, open or not; a folder with all it holds; an empty folder left out`() throws {
        var favorites = Favorites()
        let open = try FavoritesFixture.need(favorites.keep(FavoritesFixture.item(), contents: [:]))
        let closed = try FavoritesFixture.need(favorites.addEntry(home: FavoritesFixture.home(), title: "closed"))
        let folder = try FavoritesFixture.need(favorites.addFolder(named: "F"))
        let inside = try FavoritesFixture.need(
            favorites.addEntry(home: FavoritesFixture.home(), title: "in", in: folder)
        )
        favorites.addFolder(named: "empty")
        #expect(
            favorites.pinnedItems(selected: nil)
                == [.entry(open), .entry(closed), .folder(folder, openCount: 0), .entry(inside)]
        )
        favorites.setCollapsed(true, for: folder)
        #expect(favorites.pinnedItems(selected: nil) == [.entry(open), .entry(closed), .folder(folder, openCount: 0)])
    }
}
