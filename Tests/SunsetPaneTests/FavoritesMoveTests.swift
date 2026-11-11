import Foundation
import Testing

@testable import SunsetPane

@Suite("Favorites: moving") struct FavoritesMoveTests {
    /// `a b F[c] d`, with the ids by name.
    private func tree() throws -> (favorites: Favorites, ids: [String: Favorites.NodeID]) {
        var favorites = Favorites()
        var ids: [String: Favorites.NodeID] = [:]
        ids["a"] = favorites.addEntry(home: FavoritesFixture.home(), title: "a")
        ids["b"] = favorites.addEntry(home: FavoritesFixture.home(), title: "b")
        ids["F"] = favorites.addFolder(named: "F")
        ids["c"] = favorites.addEntry(home: FavoritesFixture.home(), title: "c", in: ids["F"])
        ids["d"] = favorites.addEntry(home: FavoritesFixture.home(), title: "d")
        try #require(ids.count == 5)
        return (favorites, ids)
    }

    @Test func `a node moves into a folder, out of it, and within its level`() throws {
        var (favorites, ids) = try tree()
        favorites.move([try #require(ids["a"])], into: ids["F"], at: 0)
        #expect(FavoritesFixture.shape(favorites.nodes) == "b F[a c] d")
        favorites.move([try #require(ids["c"])], into: nil, at: 0)
        #expect(FavoritesFixture.shape(favorites.nodes) == "c b F[a] d")
        favorites.move([try #require(ids["d"])], into: nil, at: 1)
        #expect(FavoritesFixture.shape(favorites.nodes) == "c d b F[a]")
    }

    @Test func `the place is counted among what is left once the moved nodes are taken out, and brought inside`() throws
    {
        var (favorites, ids) = try tree()
        favorites.move([try #require(ids["a"])], into: nil, at: 99)
        #expect(FavoritesFixture.shape(favorites.nodes) == "b F[c] d a")
        favorites.move([try #require(ids["a"])], into: nil, at: -3)
        #expect(FavoritesFixture.shape(favorites.nodes) == "a b F[c] d")
    }

    @Test func `several nodes move together, in the order they have in the tree`() throws {
        var (favorites, ids) = try tree()
        favorites.move([try #require(ids["d"]), try #require(ids["a"]), try #require(ids["c"])], into: ids["F"], at: 0)
        #expect(FavoritesFixture.shape(favorites.nodes) == "b F[a c d]")
    }

    @Test func `a folder does not move into itself or into what it holds, and unknown nodes are ignored`() throws {
        var (favorites, ids) = try tree()
        let inner = try FavoritesFixture.need(favorites.addFolder(named: "G", in: ids["F"]))
        let before = favorites
        favorites.move([try #require(ids["F"])], into: ids["F"], at: 0)
        favorites.move([try #require(ids["F"])], into: inner, at: 0)
        favorites.move([Favorites.NodeID()], into: nil, at: 0)
        favorites.move([try #require(ids["a"])], into: ids["b"], at: 0)
        #expect(favorites == before)
    }

    @Test func `a node moved with the folder that holds it moves once, inside that folder`() throws {
        var (favorites, ids) = try tree()
        let outer = try FavoritesFixture.need(favorites.addFolder(named: "O"))
        favorites.move([try #require(ids["F"]), try #require(ids["c"])], into: outer, at: 0)
        #expect(FavoritesFixture.shape(favorites.nodes) == "a b d O[F[c]]")
    }

    @Test func `a folder dropped too deep is flattened to fit: the folders past the fourth level dissolve`() throws {
        var favorites = Favorites()
        let chain = FavoritesFixture.chain(3, in: &favorites)
        let moved = try FavoritesFixture.need(favorites.addFolder(named: "M"))
        let inner = try FavoritesFixture.need(favorites.addFolder(named: "N", in: moved))
        favorites.addEntry(home: FavoritesFixture.home(), title: "x", in: moved)
        favorites.addEntry(home: FavoritesFixture.home(), title: "y", in: inner)
        let deepest = try FavoritesFixture.need(favorites.addFolder(named: "P", in: inner))
        favorites.addEntry(home: FavoritesFixture.home(), title: "z", in: deepest)
        // 1[2[3[]]] M[N[y P[z]] x]: M lands at level 4, N and P would be at 5 and 6.
        favorites.move([moved], into: chain.last, at: 0)
        #expect(FavoritesFixture.shape(favorites.nodes) == "1[2[3[M[y z x]]]]")
        #expect(favorites.folder(inner) == nil && favorites.folder(deepest) == nil)
    }

    @Test func `a folder dropped into the deepest folder dissolves there, its entries taking its place`() throws {
        var favorites = Favorites()
        let chain = FavoritesFixture.chain(4, in: &favorites)
        favorites.addEntry(home: FavoritesFixture.home(), title: "k", in: chain.last)
        let moved = try FavoritesFixture.need(favorites.addFolder(named: "M"))
        favorites.addEntry(home: FavoritesFixture.home(), title: "x", in: moved)
        favorites.addEntry(home: FavoritesFixture.home(), title: "y", in: moved)
        favorites.move([moved], into: chain.last, at: 1)
        #expect(FavoritesFixture.shape(favorites.nodes) == "1[2[3[4[k x y]]]]")
    }

    @Test func `moving keeps what is open open`() throws {
        var favorites = Favorites()
        let folder = try FavoritesFixture.need(favorites.addFolder(named: "F"))
        let item = FavoritesFixture.item()
        let id = try FavoritesFixture.need(favorites.keep(item, contents: [:]))
        favorites.move([id], into: folder, at: 0)
        #expect(favorites.entry(id)?.open == favorites.entry(containing: item.focused)?.open)
        #expect(favorites.livePanes == item.panes)
        #expect(favorites.location(of: id) == Favorites.Location(parent: folder, index: 0, level: 1))
    }
}
