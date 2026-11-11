import Foundation
import Testing

@testable import SunsetPane

@Suite("Favorites: the rows a sidebar shows") struct FavoritesRowsTests {
    private func names(_ favorites: Favorites, selected: Favorites.NodeID? = nil) -> [String] {
        favorites.rows(selected: selected)
            .map { row in
                let name =
                    switch favorites.node(row.id) {
                        case .folder(let folder): folder.name
                        case .entry(let entry): entry.title ?? "-"
                        case nil: "?"
                    }
                return String(repeating: ">", count: row.level) + name
            }
    }

    @Test func `expanded folders show what they hold, one level in`() throws {
        var favorites = Favorites()
        favorites.addEntry(home: FavoritesFixture.home(), title: "a")
        let folder = try FavoritesFixture.need(favorites.addFolder(named: "F"))
        favorites.addEntry(home: FavoritesFixture.home(), title: "b", in: folder)
        let inner = try FavoritesFixture.need(favorites.addFolder(named: "G", in: folder))
        favorites.addEntry(home: FavoritesFixture.home(), title: "c", in: inner)
        #expect(names(favorites) == ["a", "F", ">b", ">G", ">>c"])
        #expect(favorites.rows(selected: nil).map(\.isFolder) == [false, true, false, true, false])
    }

    @Test func `a collapsed folder shows only its row`() throws {
        var favorites = Favorites()
        let folder = try FavoritesFixture.need(favorites.addFolder(named: "F"))
        favorites.addEntry(home: FavoritesFixture.home(), title: "b", in: folder)
        favorites.addEntry(home: FavoritesFixture.home(), title: "z")
        favorites.setCollapsed(true, for: folder)
        #expect(names(favorites) == ["F", "z"])
    }

    @Test func `a collapsed folder shows its row and the selected entry when it is inside, however deep`() throws {
        var favorites = Favorites()
        let folder = try FavoritesFixture.need(favorites.addFolder(named: "F"))
        favorites.addEntry(home: FavoritesFixture.home(), title: "b", in: folder)
        let inner = try FavoritesFixture.need(favorites.addFolder(named: "G", in: folder))
        let selected = try FavoritesFixture.need(
            favorites.addEntry(home: FavoritesFixture.home(), title: "c", in: inner)
        )
        favorites.setCollapsed(true, for: folder)
        #expect(names(favorites, selected: selected) == ["F", ">c"])
        favorites.setCollapsed(false, for: folder)
        favorites.setCollapsed(true, for: inner)
        #expect(names(favorites, selected: selected) == ["F", ">b", ">G", ">>c"])
        #expect(names(favorites, selected: Favorites.NodeID()) == ["F", ">b", ">G"])
    }
}
