import Foundation
import SunsetPane
import Testing

@testable import SunsetShell
@testable import SunsetShellModel

/// A pinned tab or a favorite that navigated away from its own page says so, and a double click takes it back there.
@MainActor @Suite("A kept page away from where it was kept")
struct KeptEntryAwayTests {
    @Test func `away once its page is elsewhere; a double click takes it back; at home it renames as before`() throws {
        let pinned = FavoritesModel()
        let tabs = TabsModel()
        var made: [FakeContent] = []
        tabs.makeContent = { descriptor in
            let content = FakeContent(descriptor)
            made.append(content)
            return content
        }
        tabs.pinned = pinned
        tabs.newTab(PaneDescriptor(kind: "web", state: ["url": "https://mail.example/inbox"]))
        let item = try #require(tabs.workspace.selectedID)
        let pinnedEntry = tabs.pin(item: item)
        let entry = try #require(pinnedEntry)
        let kept = try #require(pinned.favorites.entry(entry))
        #expect(!tabs.isAway(entry: kept), "where it was kept")
        let page = try #require(made.last)
        page.descriptor = PaneDescriptor(kind: "web", state: ["url": "https://mail.example/inbox#unread"])
        #expect(!tabs.isAway(entry: kept), "a fragment is the same page")
        page.descriptor = PaneDescriptor(kind: "web", state: ["url": "https://mail.example/message/42"])
        let moved = try #require(pinned.favorites.entry(entry))
        #expect(tabs.isAway(entry: moved))
        tabs.doubleClick(entry: entry)
        let back = try #require(pinned.favorites.entry(entry))
        #expect(!tabs.isAway(entry: back) && tabs.renamingRow == nil, "taken back, not renamed")
        tabs.doubleClick(entry: entry)
        #expect(tabs.renamingRow == .node(entry), "at home, a double click renames")
    }

    @Test func `a terminal is never away: its folder changes as it works`() throws {
        let pinned = FavoritesModel()
        let tabs = TabsModel()
        var made: [FakeContent] = []
        tabs.makeContent = { descriptor in
            let content = FakeContent(descriptor)
            made.append(content)
            return content
        }
        tabs.pinned = pinned
        tabs.newTab(.terminal(directory: "/tmp"))
        let item = try #require(tabs.workspace.selectedID)
        let pinnedEntry = tabs.pin(item: item)
        let entry = try #require(pinnedEntry)
        try #require(made.last).descriptor = .terminal(directory: "/usr")
        let worked = try #require(pinned.favorites.entry(entry))
        #expect(!tabs.isAway(entry: worked))
    }

    /// A double click on a tile "stayed on the current page or nothing happened". Its cause: the tile was a button (with a
    /// drag), which took the clicks before a gesture saw two. A tile now takes its clicks as a row does, a click showing it
    /// and a double click (a gesture of its own) going through `doubleClick(entry:)`.
    @Test func `a tile's click shows it as it is; its double click takes an away page back`() throws {
        let pinned = FavoritesModel()
        let tabs = TabsModel()
        var made: [FakeContent] = []
        tabs.makeContent = { descriptor in
            let content = FakeContent(descriptor)
            made.append(content)
            return content
        }
        tabs.pinned = pinned
        tabs.newTab(PaneDescriptor(kind: "web", state: ["url": "https://mail.example/inbox"]))
        let item = try #require(tabs.workspace.selectedID)
        let pinnedEntry = tabs.pin(item: item)
        let entry = try #require(pinnedEntry)
        try #require(made.last).descriptor = PaneDescriptor(kind: "web", state: ["url": "https://mail.example/m/1"])
        tabs.select(entry: entry)
        let still = try #require(pinned.favorites.entry(entry))
        #expect(tabs.isAway(entry: still), "one click shows it as it is")
        tabs.doubleClick(entry: entry)
        let back = try #require(pinned.favorites.entry(entry))
        #expect(!tabs.isAway(entry: back))
    }

    /// "the edit command should only show for pinned/favorites terminal tabs".
    @Test func `only a kept terminal has a command to edit`() throws {
        let pinned = FavoritesModel()
        let tabs = TabsModel()
        tabs.makeContent = { FakeContent($0) }
        tabs.pinned = pinned
        tabs.newTab(PaneDescriptor(kind: "web", state: ["url": "https://mail.example/"]))
        let first = try #require(tabs.workspace.selectedID)
        let pinnedPage = tabs.pin(item: first)
        let page = try #require(pinnedPage)
        tabs.newTab(.terminal(directory: "/tmp"))
        let second = try #require(tabs.workspace.selectedID)
        let pinnedShell = tabs.pin(item: second)
        let shell = try #require(pinnedShell)
        let pageEntry = try #require(pinned.favorites.entry(page))
        let shellEntry = try #require(pinned.favorites.entry(shell))
        #expect(!tabs.runsTerminal(pageEntry) && tabs.runsTerminal(shellEntry))
    }
}
