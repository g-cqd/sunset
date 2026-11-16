import Foundation
import Testing

@testable import SunsetPane

/// A new Space starts with a copy of the Favorites of the Space it was made from (the owner, 2026-11-17): the same folders
/// and entries, none open, and nothing shared with the original (a pane is in one place).
@Suite("A copy of the Favorites")
struct FavoritesCopyTests {
    @Test func `the copy has the same tree, names, icons, homes and commands; none of its ids, and nothing open`()
        throws
    {
        var favorites = Favorites()
        let madeFolder = favorites.addFolder(named: "Servers")
        let folder = try #require(madeFolder)
        favorites.setIcon(.emoji("\u{1F5A5}"), for: folder)
        var tabs = Workspace()
        let tab = tabs.add()
        let added = tabs.addPane(beside: tab.pane, edge: .right)
        let split = try #require(added)
        let item = try #require(tabs.items.first)
        let kept = favorites.keep(
            item,
            contents: [tab.pane: .terminal(directory: "/srv"), split: .terminal(directory: "/var")],
            in: folder
        )
        let open = try #require(kept)
        favorites.rename(open, to: "Logs")
        favorites.setCommand("tail -f log", seal: "sealed", for: open)
        let copy = favorites.copied()
        #expect(copy.count == 2 && copy.entries.count == 1 && copy.livePanes.isEmpty)
        guard case .folder(let copiedFolder)? = copy.nodes.first else {
            Issue.record("the folder is not the first node of the copy")
            return
        }
        #expect(copiedFolder.name == "Servers" && copiedFolder.icon == .emoji("\u{1F5A5}") && copiedFolder.id != folder)
        let entry = try #require(copy.entries.first)
        #expect(entry.title == "Logs" && entry.command == "tail -f log" && entry.commandSeal == "sealed")
        #expect(entry.id != open && !entry.isOpen)
        // The same layout, with panes of its own; what each starts from follows its pane.
        #expect(entry.home.layout.panes.count == 2 && Set(entry.home.layout.panes).isDisjoint(with: [tab.pane, split]))
        #expect(entry.home.layout.panes.map { entry.home.contents[$0]?.directory } == ["/srv", "/var"])
        #expect(entry.home.layout.panes.contains(entry.home.focused))
        // The original is untouched.
        #expect(favorites.entry(open)?.isOpen == true)
    }
}
