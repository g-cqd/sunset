import SunsetPane
import Testing

@testable import SunsetShell

@MainActor @Suite("Names and icons in place") struct TabsNamingTests {
    @Test func `a tab, an entry and a folder are renamed in place; a blank name gives a tab its content's title back`()
        throws
    {
        let harness = TabsHarness()
        harness.tabs.newTab()
        harness.tabs.newTab()
        let tab = harness.tabs.workspace.items[0].id
        harness.tabs.renamingRow = .tab(tab)
        #expect(harness.tabs.name(of: .tab(tab)) == "fake")
        harness.tabs.rename(.tab(tab), to: "logs")
        #expect(harness.tabs.workspace.items[0].customTitle == "logs" && harness.tabs.renamingRow == nil)
        harness.tabs.rename(.tab(tab), to: "  ")
        #expect(harness.tabs.workspace.items[0].customTitle == nil)
        harness.tabs.keep(item: harness.tabs.workspace.items[1].id)
        let entry = try #require(harness.tabs.workspace.selectedEntry)
        harness.tabs.rename(.node(entry), to: "server")
        #expect(
            harness.tabs.favorites.favorites.entry(entry)?.title == "server"
                && harness.tabs.name(of: .node(entry)) == "server"
        )
        harness.tabs.newFolder()
        let folder = try #require(
            harness.tabs.favorites.favorites.nodes.compactMap { if case .folder(let f) = $0 { f.id } else { nil } }
                .first
        )
        harness.tabs.rename(.node(folder), to: "work")
        #expect(harness.tabs.name(of: .node(folder)) == "work")
    }

    @Test func `an icon and its colour are given to a tab, an entry or a folder, and taken back`() throws {
        let harness = TabsHarness()
        harness.tabs.newTab()
        let tab = harness.tabs.workspace.items[0].id
        let red = IconColor(red: 255, green: 0, blue: 0)
        harness.tabs.setIcon(.symbol("bolt", color: red), for: .tab(tab))
        #expect(harness.tabs.icon(of: .tab(tab)) == .symbol("bolt", color: red))
        harness.tabs.setIcon(harness.tabs.icon(of: .tab(tab))?.colored(nil), for: .tab(tab))
        #expect(harness.tabs.icon(of: .tab(tab)) == .symbol("bolt"))
        harness.tabs.newFolder()
        let folder = try #require(harness.tabs.favorites.favorites.nodes.first?.id)
        harness.tabs.setIcon(.emoji("📦"), for: .node(folder))
        #expect(harness.tabs.icon(of: .node(folder)) == .emoji("📦"))
        harness.tabs.setIcon(nil, for: .node(folder))
        #expect(harness.tabs.icon(of: .node(folder)) == nil)
    }
}
