import Foundation
import Testing

@testable import SunsetPane

@Suite("Saved session: Favorites") struct SavedFavoritesTests {
    private func window(selecting entry: Favorites.NodeID? = nil, tabs: Int = 1) -> SavedWindow {
        var workspace = Workspace()
        for _ in 0 ..< tabs { workspace.add() }
        if let entry { workspace.select(entry: entry) }
        return SavedWindow(workspace: workspace)
    }

    private func reread(_ session: SavedSession) throws -> SavedSession {
        try #require(SavedSession(data: try session.encoded()))
    }

    @Test func `a session reads back with its Favorites and what brings the live entries back`() throws {
        var favorites = Favorites()
        let item = FavoritesFixture.item(panes: 2)
        let open = try FavoritesFixture.need(favorites.keep(item, contents: [:]))
        favorites.addEntry(home: FavoritesFixture.home(), title: "closed")
        let live: [PaneID: PaneDescriptor] = [
            item.panes[0]: .terminal(directory: "/now"), PaneID(): .terminal(directory: "/stray")
        ]
        let saved = SavedFavorites(favorites: favorites, contents: live)
        #expect(saved.contents == [item.panes[0]: .terminal(directory: "/now")], "only the live panes")
        let session = SavedSession(windows: [window(selecting: open)], favorites: saved)
        let read = try reread(session)
        #expect(read == session && read.favorites.favorites == favorites)
        #expect(read.windows[0].workspace.selectedEntry == open)
    }

    @Test func `the file says version 2, and a version 1 file is read as windows with no Favorites`() throws {
        let session = SavedSession(windows: [window()])
        let text = String(decoding: try session.encoded(), as: UTF8.self)
        #expect(text.contains("\"version\" : 2"))
        let old = Data(text.replacingOccurrences(of: "\"version\" : 2", with: "\"version\" : 1").utf8)
        var object = try JSONSerialization.jsonObject(with: old) as? [String: Any] ?? [:]
        object["favorites"] = nil
        let read = try #require(SavedSession(data: try JSONSerialization.data(withJSONObject: object)))
        #expect(read.windows == session.windows && read.favorites == SavedFavorites())
        let future = Data(text.replacingOccurrences(of: "\"version\" : 2", with: "\"version\" : 3").utf8)
        #expect(SavedSession(data: future) == nil)
    }

    @Test func `an entry live on a pane that a window holds is read as closed`() throws {
        var workspace = Workspace()
        let tab = workspace.add()
        var favorites = Favorites()
        let pane = tab.pane
        let clash = Workspace.Item(layout: .pane(pane), focused: pane)
        let id = try FavoritesFixture.need(favorites.keep(clash, contents: [:]))
        let session = SavedSession(
            windows: [SavedWindow(workspace: workspace)],
            favorites: SavedFavorites(favorites: favorites)
        )
        #expect(session.favorites.favorites.entry(id)?.isOpen == false)
        #expect(session.windows[0].workspace.allPanes == [pane])
    }

    @Test func `a window's selected entry that is not open, or not there, is not selected`() throws {
        var favorites = Favorites()
        let closed = try FavoritesFixture.need(favorites.addEntry(home: FavoritesFixture.home(), title: "closed"))
        let open = try FavoritesFixture.need(favorites.keep(FavoritesFixture.item(), contents: [:]))
        let saved = SavedFavorites(favorites: favorites)
        let session = SavedSession(
            windows: [window(selecting: closed), window(selecting: Favorites.NodeID()), window(selecting: open)],
            favorites: saved
        )
        #expect(session.windows.map(\.workspace.selectedEntry) == [nil, nil, open])
    }

    @Test func `a window with no tab is kept when it shows an open entry, and left out otherwise`() throws {
        var favorites = Favorites()
        let open = try FavoritesFixture.need(favorites.keep(FavoritesFixture.item(), contents: [:]))
        let session = SavedSession(
            windows: [window(selecting: open, tabs: 0), window(tabs: 0)],
            favorites: SavedFavorites(favorites: favorites)
        )
        #expect(session.windows.count == 1 && session.windows[0].workspace.selectedEntry == open)
        #expect(try reread(session) == session)
    }

    @Test func `Favorites that cannot be read are no Favorites, and the windows are still read`() throws {
        let session = SavedSession(windows: [window()])
        var object = try JSONSerialization.jsonObject(with: try session.encoded()) as? [String: Any] ?? [:]
        object["favorites"] = ["favorites": 3]
        let read = try #require(SavedSession(data: try JSONSerialization.data(withJSONObject: object)))
        #expect(read.windows == session.windows && read.favorites == SavedFavorites())
    }
}
