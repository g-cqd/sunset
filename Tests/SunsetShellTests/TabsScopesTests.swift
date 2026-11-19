import Foundation
import SunsetPane
import Testing

@testable import SunsetShell
@testable import SunsetShellModel

/// A window when a scope of the app is off (roadmap 0033; the owner's answers of 2026-11-17): nothing of the scope is
/// made; its tabs close; what is kept of it is hidden, and comes back.
@MainActor
@Suite("A window and the scopes that are off")
struct TabsScopesTests {
    private func window(_ made: MadeContents, pinned: FavoritesModel? = nil) -> TabsModel {
        let tabs = TabsModel()
        tabs.makeContent = { descriptor in
            let content = FakeContent(descriptor ?? .terminal(directory: nil))
            made.all.append(content)
            return content
        }
        tabs.pinned = pinned
        return tabs
    }

    private let page = PaneDescriptor(kind: "web", state: ["url": "https://example.com"])

    @Test func `with terminals off a new tab is the command bar on no tab; a page is still made; a terminal is not`() {
        let made = MadeContents()
        let tabs = window(made)
        tabs.scopes = Scopes(terminal: false)
        tabs.newTab()
        #expect(tabs.workspace.isEmpty && made.all.isEmpty && tabs.bar?.purpose == .search)
        tabs.bar = nil
        tabs.newTab(.terminal(directory: "/tmp"))
        #expect(tabs.workspace.isEmpty && made.all.isEmpty, "refused")
        tabs.newTab(page)
        #expect(tabs.workspace.count == 1 && made.all.map(\.descriptor.kind) == ["web"])
        // A split has no terminal to make either: the bar asks which tab to put beside.
        let pane = tabs.workspace.selectedPane
        tabs.newSplit(.right)
        #expect(tabs.workspace.selectedItem?.panes.count == 1 && made.all.count == 1)
        #expect(tabs.bar?.purpose == pane.map { .splitWith(SplitChoice(pane: $0, edge: .right)) })
        // With the web off, a page is not made.
        tabs.scopes = Scopes(web: false)
        tabs.newTab(page)
        #expect(tabs.workspace.count == 1)
    }

    @Test func `a scope turned off closes its panes: a tab of only those goes, a split keeps the others`() throws {
        let made = MadeContents()
        let tabs = window(made)
        tabs.newTab()
        tabs.newTab(page)
        tabs.newTab()
        let third = try #require(tabs.workspace.selectedPane)
        let beside = FakeContent(page)
        made.all.append(beside)
        tabs.split(.right, with: beside, beside: made.all[2])
        #expect(tabs.workspace.count == 3 && made.all.map(\.descriptor.kind) == ["terminal", "web", "terminal", "web"])
        #expect(tabs.space.count(of: .web) == 2)
        tabs.space.close(.web)
        #expect(tabs.workspace.count == 2 && tabs.workspace.items[1].panes == [third])
        #expect(made.all.map(\.stopped) == [false, true, false, true])
        #expect(tabs.space.count(of: .web) == 0 && tabs.space.count(of: .terminal) == 2)
    }

    @Test func `what is kept of a scope that is off is hidden, unloaded, and comes back as it was`() throws {
        let (made, pinned) = (MadeContents(), FavoritesModel())
        let tabs = window(made, pinned: pinned)
        tabs.newTab(page)
        let first = try #require(tabs.workspace.selectedID)
        let grid = try #require(tabs.pin(item: first))
        tabs.newTab(page)
        let second = try #require(tabs.workspace.selectedID)
        let kept = try #require(tabs.keep(item: second))
        tabs.newTab()
        let third = try #require(tabs.workspace.selectedID)
        let shell = try #require(tabs.keep(item: third))
        #expect(tabs.pinnedEntries.count == 1 && tabs.shownFavorites.count == 2)
        // Turned off: unloaded, not removed; not listed.
        pinned.unload(.web)
        tabs.favorites.unload(.web)
        tabs.scopes = Scopes(web: false)
        #expect(made.all.map(\.stopped) == [true, true, false])
        #expect(tabs.pinnedEntries.isEmpty && tabs.shownFavorites.map(\.id) == [shell])
        #expect(pinned.favorites.entry(grid)?.isOpen == false && tabs.favorites.favorites.entry(kept) != nil)
        #expect(tabs.shownEntry?.id != kept && tabs.shownEntry?.id != grid, "no window shows what is hidden")
        tabs.select(entry: kept)
        #expect(tabs.shownEntry?.id != kept && made.all.count == 3, "and it cannot be opened")
        // Turned on again: back as it was.
        tabs.scopes = Scopes()
        #expect(tabs.pinnedEntries.map(\.id) == [grid] && tabs.shownFavorites.map(\.id) == [kept, shell])
        tabs.select(entry: kept)
        #expect(made.all.count == 4 && made.all[3].descriptor == page)
    }
}
