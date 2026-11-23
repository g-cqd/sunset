import Foundation
import SunsetPane
import Testing

@testable import SunsetShell
@testable import SunsetShellModel

/// The tab menu's Duplicate, Copy Address and Share (n136): on the row, or on every selected row with it; folders give
/// the addresses of everything in them.
@MainActor
@Suite("Duplicating and the addresses of the selected rows")
struct TabsDuplicateTests {
    private func window(_ made: MadeContents) -> TabsModel {
        let tabs = TabsModel()
        tabs.makeContent = { descriptor in
            let content = FakeContent(descriptor)
            made.all.append(content)
            return content
        }
        return tabs
    }

    private static func page(_ address: String) throws -> PaneDescriptor {
        .page(try #require(URL(string: address)))
    }

    @Test func `duplicating tabs puts each copy right after its tab, its splits and its contents copied`() throws {
        let made = MadeContents()
        let tabs = window(made)
        tabs.newTab(try Self.page("https://a.example/"))
        tabs.newTab(try Self.page("https://b.example/"))
        tabs.newSplit(.right)
        tabs.newTab(try Self.page("https://c.example/"))
        let ids = tabs.workspace.items.map(\.id)
        tabs.duplicate([.tab(ids[0]), .tab(ids[1])])
        let items = tabs.workspace.items
        #expect(items.count == 5)
        #expect(items[0].id == ids[0] && items[2].id == ids[1] && items[4].id == ids[2])
        #expect(items[3].panes.count == 2 && items[3].layout.panes != items[2].layout.panes)
        let copied = items[1].panes.compactMap { tabs.content($0)?.descriptor.state["url"] }
        #expect(copied == ["https://a.example/"])
        #expect(tabs.content(items[3].panes[0])?.descriptor == tabs.content(items[2].panes[0])?.descriptor)
        #expect(tabs.content(items[3].panes[0]) !== tabs.content(items[2].panes[0]), "a content of its own")
    }

    @Test func `the addresses are the pages' of the tabs, and of every entry in a folder, in order`() throws {
        let made = MadeContents()
        let tabs = window(made)
        tabs.newTab(try Self.page("https://a.example/"))
        tabs.newTab(.terminal(directory: nil))
        tabs.newTab(try Self.page("https://b.example/"))
        tabs.newTab(try Self.page("https://c.example/"))
        let ids = tabs.workspace.items.map(\.id)
        let kept = try #require(tabs.keep(item: ids[2], show: false))
        let other = try #require(tabs.keep(item: ids[3], show: false))
        var folder: Favorites.NodeID?
        tabs.favorites.edit { folder = $0.addFolder(named: "F") }
        let made2 = try #require(folder)
        tabs.favorites.edit { $0.move([kept, other], into: made2, at: 0) }
        let addresses = tabs.addresses(of: [.tab(ids[0]), .tab(ids[1]), .node(made2)]).map(\.absoluteString)
        #expect(addresses == ["https://a.example/", "https://b.example/", "https://c.example/"])
        #expect(tabs.addresses(of: [.tab(ids[1])]).isEmpty, "a terminal has none")
    }
}
