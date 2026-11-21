import Foundation
import Testing

@testable import SunsetImport
@testable import SunsetPane

/// Another browser's bookmarks as Favorites (roadmap 0111 A): folders kept as far as Favorites nest, links as entries that
/// are not open, each one web page at its address; what Sunset does not open left out and counted.
@Suite("Bookmarks as Favorites")
struct FavoritesImportTests {
    private func link(_ title: String, _ address: String) -> BookmarkNode {
        .link(BookmarkLink(title: title, address: address))
    }

    private func folder(_ name: String, _ children: [BookmarkNode]) -> BookmarkNode {
        .folder(BookmarkFolder(name: name, children: children))
    }

    @Test func `links become closed entries, homed on one web page at their address, in their folders`() throws {
        let (favorites, report) = FavoritesImport.favorites(from: [
            link("Swift", "https://swift.org/"),
            folder("Engines", [link("WebKit", "https://webkit.org/")])
        ])
        #expect(report == ImportReport(links: 2, folders: 1, leftOut: 0))
        #expect(favorites.nodes.count == 2)
        let swift = try #require(favorites.entries.first)
        #expect(swift.title == "Swift")
        #expect(!swift.isOpen)
        #expect(
            swift.home.contents.values.map(\.self) == [
                PaneDescriptor.page(try #require(URL(string: "https://swift.org/")))
            ]
        )
        #expect(swift.home.holdsTogether)
        let engines = try #require(favorites.nodes.last)
        guard case .folder(let made) = engines else {
            Issue.record("not a folder")
            return
        }
        #expect(made.name == "Engines")
        #expect(made.children.count == 1)
    }

    @Test func `what Sunset does not open is left out and counted: bookmarklets, a browser's own pages, nonsense`() {
        let (favorites, report) = FavoritesImport.favorites(from: [
            link("Bookmarklet", "javascript:alert(1)"),
            link("Settings", "chrome://settings"),
            link("Nothing", "not an address"),
            link("A file", "file:///Users/someone/notes.html"),
            link("Kept", "http://example.org/")
        ])
        #expect(report == ImportReport(links: 2, folders: 0, leftOut: 3))
        #expect(favorites.entries.map(\.title) == ["A file", "Kept"])
    }

    @Test func `folders deeper than Favorites nest give what they hold to the deepest folder there may be`() throws {
        var deep: BookmarkNode = link("Bottom", "https://bottom.example/")
        for level in (1 ... Favorites.maximumDepth + 2).reversed() { deep = folder("Level \(level)", [deep]) }
        let (favorites, report) = FavoritesImport.favorites(from: [deep])
        #expect(report == ImportReport(links: 1, folders: Favorites.maximumDepth, leftOut: 0))
        var levels = 0
        var deepestHolds: [Favorites.Node] = []
        favorites.walk { node, location in
            if case .folder(let folder) = node {
                levels = max(levels, location.level + 1)
                if location.level + 1 == Favorites.maximumDepth { deepestHolds = folder.children }
            }
        }
        #expect(levels == Favorites.maximumDepth)
        #expect(deepestHolds.count == 1)
    }

    @Test func `a folder without a name is named, and past the most Favorites hold the rest is left out`() {
        let many = (0 ..< Favorites.maximumNodes + 10).map { link("\($0)", "https://example.org/\($0)") }
        let (favorites, report) = FavoritesImport.favorites(from: [folder("  ", many)])
        #expect(report.folders == 1)
        #expect(report.links == Favorites.maximumNodes - 1)
        #expect(report.leftOut == 11)
        #expect(favorites.count == Favorites.maximumNodes)
        guard case .folder(let made) = favorites.nodes.first else {
            Issue.record("no folder")
            return
        }
        #expect(made.name == FavoritesImport.unnamedFolder)
    }
}
