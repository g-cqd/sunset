import Foundation
import Testing

@testable import SunsetPane

@Suite("Favorites: the saved form") struct FavoritesCodableTests {
    private func roundTrip(_ favorites: Favorites) throws -> Favorites {
        try JSONDecoder().decode(Favorites.self, from: JSONEncoder().encode(favorites))
    }

    private func json(_ favorites: Favorites) throws -> [String: Any] {
        try JSONSerialization.jsonObject(with: JSONEncoder().encode(favorites)) as? [String: Any] ?? [:]
    }

    private func read(_ object: [String: Any]) throws -> Favorites {
        try JSONDecoder().decode(Favorites.self, from: JSONSerialization.data(withJSONObject: object))
    }

    /// `a F[b G[c]]`: `a` open and split, `F` collapsed with an icon, `c` closed with an icon.
    private func sample() throws -> Favorites {
        var favorites = Favorites()
        var item = FavoritesFixture.item(panes: 2)
        item.customTitle = "a"
        favorites.keep(item, contents: [item.focused: .terminal(directory: "/a")])
        let folder = try FavoritesFixture.need(favorites.addFolder(named: "F"))
        favorites.setIcon(.symbol("folder.fill"), for: folder)
        favorites.setCollapsed(true, for: folder)
        favorites.addEntry(home: FavoritesFixture.home("/b"), title: "b", in: folder)
        let inner = try FavoritesFixture.need(favorites.addFolder(named: "G", in: folder))
        favorites.addEntry(home: FavoritesFixture.home("/c"), title: "c", icon: .emoji("🌙"), in: inner)
        return favorites
    }

    @Test func `a tree reads back as itself: folders, collapsed state, icons, homes, and what is open`() throws {
        let favorites = try sample()
        #expect(try roundTrip(favorites) == favorites)
        #expect(try roundTrip(Favorites()) == Favorites())
    }

    @Test func `a damaged node is left out and the rest is read`() throws {
        var object = try json(try sample())
        var nodes = object["nodes"] as? [[String: Any]] ?? []
        nodes[0]["home"] = "nonsense"
        nodes.append(["kind": "mystery", "id": UUID().uuidString])
        object["nodes"] = nodes
        #expect(FavoritesFixture.shape(try read(object).nodes) == "F[b G[c]]")
    }

    @Test func `an entry whose home does not hold together is left out; a live form that does not is read as closed`()
        throws
    {
        var favorites = Favorites()
        let item = FavoritesFixture.item()
        favorites.keep(item, contents: [:])
        favorites.addEntry(home: FavoritesFixture.home(), title: "b")
        var object = try json(favorites)
        var nodes = object["nodes"] as? [[String: Any]] ?? []
        var open = nodes[0]["open"] as? [String: Any] ?? [:]
        open["focused"] = UUID().uuidString
        nodes[0]["open"] = open
        var home = nodes[1]["home"] as? [String: Any] ?? [:]
        home["focused"] = UUID().uuidString
        nodes[1]["home"] = home
        object["nodes"] = nodes
        let read = try read(object)
        #expect(read.entries.count == 1 && read.entries[0].isOpen == false)
    }

    @Test func `a file nested deeper than four levels is flattened to fit`() throws {
        func folder(_ name: String, _ children: [[String: Any]]) -> [String: Any] {
            ["kind": "folder", "id": UUID().uuidString, "name": name, "collapsed": false, "children": children]
        }
        let deep = folder("1", [folder("2", [folder("3", [folder("4", [folder("5", [folder("6", [])])])])])])
        #expect(FavoritesFixture.shape(try read(["nodes": [deep]]).nodes) == "1[2[3[4[]]]]")
    }

    @Test func `a node whose id was seen before is left out`() throws {
        var object = try json(try sample())
        var nodes = object["nodes"] as? [[String: Any]] ?? []
        nodes.append(nodes[1])
        object["nodes"] = nodes
        #expect(FavoritesFixture.shape(try read(object).nodes) == "a F[b G[c]]")
    }

    @Test func `two entries live on the same pane: the second is read as closed`() throws {
        var favorites = Favorites()
        favorites.keep(FavoritesFixture.item(), contents: [:])
        favorites.keep(FavoritesFixture.item(), contents: [:])
        var object = try json(favorites)
        var nodes = object["nodes"] as? [[String: Any]] ?? []
        nodes[1]["open"] = nodes[0]["open"]
        object["nodes"] = nodes
        let read = try read(object)
        #expect(read.entries.map(\.isOpen) == [true, false])
    }

    @Test func `a file with more nodes than the bound is cut at the bound`() throws {
        let home = try JSONSerialization.jsonObject(with: JSONEncoder().encode(FavoritesFixture.home()))
        let nodes: [[String: Any]] = (0 ..< Favorites.maximumNodes + 10)
            .map { _ in
                ["kind": "entry", "id": UUID().uuidString, "home": home]
            }
        #expect(try read(["nodes": nodes]).count == Favorites.maximumNodes)
    }
}
