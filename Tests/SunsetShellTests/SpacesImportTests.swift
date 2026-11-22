import Foundation
import Testing

@testable import SunsetPane
@testable import SunsetShellModel

/// Another browser's bookmarks brought into Sunset.
@MainActor @Suite("Bookmarks imported into a Space")
struct SpacesImportTests {
    private func imported(_ count: Int) -> Favorites {
        var favorites = Favorites()
        let nodes = (0 ..< count)
            .compactMap { index -> Favorites.Node? in
                let pane = PaneID()
                guard let address = URL(string: "https://example.org/\(index)") else { return nil }
                return Favorites.newEntry(
                    home: Favorites.Home(layout: .pane(pane), focused: pane, contents: [pane: .page(address)]),
                    title: "\(index)"
                )
            }
        favorites.append(nodes)
        return favorites
    }

    @Test func `into this Space: one folder at the end of its Favorites, what was there kept`() throws {
        let spaces = SpacesModel(makeFavorites: { FavoritesModel() })
        let space = try #require(spaces.spaces.first)
        space.favorites.edit { _ = $0.addFolder(named: "Mine") }
        let went = spaces.importFavorites(imported(3), folder: "Brave (Me)", into: space, newSpace: "unused")
        #expect(went === space)
        #expect(spaces.spaces.count == 1)
        let names = space.favorites.favorites.nodes.compactMap { node -> String? in
            if case .folder(let folder) = node { folder.name } else { nil }
        }
        #expect(names == ["Mine", "Brave (Me)"])
        #expect(space.favorites.favorites.entries.count == 3)
    }

    @Test func `into a new Space, named for the browser's profile`() {
        let spaces = SpacesModel(makeFavorites: { FavoritesModel() })
        let went = spaces.importFavorites(imported(2), folder: "Firefox (default)", into: nil, newSpace: "Firefox")
        #expect(spaces.spaces.count == 2)
        #expect(went.space.name == "Firefox")
        #expect(went.favorites.favorites.entries.count == 2)
    }
}
