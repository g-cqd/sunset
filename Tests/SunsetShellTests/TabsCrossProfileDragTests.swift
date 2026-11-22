import SunsetPane
import Testing

@testable import SunsetShell
@testable import SunsetShellModel

/// A tab or a favourite dragged into a window of another profile "moves, reload": it goes there, and its pages load
/// again as that profile (as when a Space is given another profile); a terminal moves as it is.
@MainActor
@Suite("Dragging into a window of another profile", .serialized)
struct TabsCrossProfileDragTests {
    private let page = PaneDescriptor(kind: "web", state: ["url": "https://a.example/"])

    @Test func `a page's tab moves to the other profile's Space and loads again there; a terminal runs on`() throws {
        let one = SpaceHarness(favorites: FavoritesModel())
        let two = SpaceHarness(favorites: FavoritesModel())
        let first = one.window()
        first.newTab(page)
        first.newTab()
        let pageTab = first.workspace.items[0].id
        let terminalTab = first.workspace.items[1].id
        let second = two.window()
        second.newTab()
        let oldPage = try #require(one.content(tab: 0))
        let terminal = try #require(one.content(tab: 1))

        _ = first.itemProvider(for: .item(pageTab))
        #expect(second.dropDragged(in: .today(at: 0)))
        #expect(second.workspace.items.first?.id == pageTab)
        #expect(oldPage.stopped, "the page of the first profile stopped")
        let newPage = try #require(two.content(second.workspace.items[0].focused))
        #expect(newPage !== oldPage && newPage.descriptor == page, "made again from where it was")

        _ = first.itemProvider(for: .item(terminalTab))
        #expect(second.dropDragged(in: .today(at: 0)))
        #expect(!terminal.stopped && two.content(second.workspace.items[0].focused) === terminal)
    }

    @Test func `a favourite of another profile comes as a tab, or kept in this profile's Favorites`() throws {
        let theirs = FavoritesModel()
        let ours = FavoritesModel()
        let one = SpaceHarness(favorites: theirs)
        let two = SpaceHarness(favorites: ours)
        let first = one.window()
        first.newTab()
        first.newTab()
        let a = try #require(first.keep(item: first.workspace.items[0].id, show: false))
        let b = try #require(first.keep(item: first.workspace.items[0].id, show: false))
        let second = two.window()
        _ = first.itemProvider(for: .entry(a))
        #expect(second.canDropDragged(in: .today(at: 0)))
        #expect(second.dropDragged(in: .today(at: 0)))
        #expect(second.workspace.count == 1 && theirs.favorites.entries.map(\.id) == [b])
        _ = first.itemProvider(for: .entry(b))
        #expect(second.dropDragged(in: .favorites(in: nil, at: nil)))
        #expect(theirs.favorites.entries.isEmpty && ours.favorites.entries.count == 1)
    }
}
