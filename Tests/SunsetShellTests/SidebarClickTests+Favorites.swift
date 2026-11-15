import AppKit
import SunsetPane
import Testing

@testable import SunsetShell

/// The same for the rows of the Favorites: a kept entry and a folder.
extension SidebarClickTests {
    func isCollapsed(_ id: Favorites.NodeID) -> Bool {
        if case .folder(let folder)? = tabs.favorites.favorites.node(id) { return folder.isCollapsed }
        return false
    }

    @Test func `a click on a favourite shows it at once`() async throws {
        tabs.newTab()
        tabs.newTab()
        let kept = try #require(tabs.keep(item: tabs.workspace.items[0].id, show: false))
        let window = await hosted()
        defer { window.close() }
        #expect(tabs.workspace.selectedEntry == nil)
        await click(window, at: row(0))
        let took = try #require(await looks { tabs.workspace.selectedEntry == kept }, "the click did nothing")
        #expect(took <= Self.atOnce, "the favourite was shown \(took * 5) ms after the click")
    }

    @Test func `a click on a folder folds it at once; a double click renames it and leaves it as it was`() async throws
    {
        tabs.newTab()
        tabs.newFolder()
        let folder = try #require(tabs.favorites.favorites.nodes.first?.id)
        tabs.renamingRow = nil
        let window = await hosted()
        defer { window.close() }
        await click(window, at: row(0))
        let took = try #require(await looks { isCollapsed(folder) }, "the click did nothing")
        #expect(took <= Self.atOnce, "the folder folded \(took * 5) ms after the click")

        try? await Task.sleep(for: .milliseconds(700))
        await click(window, at: row(0), count: 2)
        #expect(await looks { tabs.renamingRow == .node(folder) } != nil, "the double click did not rename")
        #expect(isCollapsed(folder), "folded before the double click, folded after it")
    }
}
