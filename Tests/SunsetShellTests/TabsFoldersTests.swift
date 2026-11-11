import SunsetPane
import Testing

@testable import SunsetShell

@MainActor @Suite("Folders from a window") struct TabsFoldersTests {
    private func window(_ count: Int) -> TabsHarness {
        let harness = TabsHarness()
        for _ in 0 ..< count { harness.tabs.newTab() }
        return harness
    }

    private func folder(_ harness: TabsHarness) -> Favorites.Folder? {
        harness.tabs.favorites.favorites.nodes.compactMap { if case .folder(let folder) = $0 { folder } else { nil } }
            .first
    }

    @Test func `New Folder makes an empty 'New Folder' at the end, its name being edited`() throws {
        let harness = window(1)
        harness.tabs.newFolder()
        let made = try #require(folder(harness))
        #expect(made.name == "New Folder" && made.children.isEmpty && harness.tabs.renamingNode == made.id)
        #expect(!harness.emptied && harness.tabs.workspace.count == 1)
    }

    @Test func `New Folder with This Tab keeps the tab, running, in a new folder`() throws {
        let harness = window(2)
        let tab = harness.tabs.workspace.items[0]
        let content = try #require(harness.content(tab.focused))
        harness.tabs.newFolder(with: tab.id)
        let made = try #require(folder(harness))
        #expect(made.children.count == 1 && harness.tabs.workspace.count == 1 && !content.stopped)
        #expect(harness.tabs.favorites.favorites.entry(containing: tab.focused) != nil)
    }

    @Test func `a tab or an entry dropped on a folder goes inside it; a pane does not`() throws {
        let harness = window(3)
        harness.tabs.newFolder()
        let made = try #require(folder(harness))
        _ = harness.tabs.itemProvider(for: .item(harness.tabs.workspace.items[0].id))
        #expect(harness.tabs.dropDragged(intoFolder: made.id))
        harness.tabs.keep(item: harness.tabs.workspace.items[0].id)
        let loose = try #require(harness.tabs.workspace.selectedEntry)
        _ = harness.tabs.itemProvider(for: .entry(loose))
        #expect(harness.tabs.dropDragged(intoFolder: made.id))
        #expect(try #require(folder(harness)).children.count == 2)
        _ = harness.tabs.itemProvider(for: .pane(harness.tabs.workspace.items[0].focused))
        #expect(!harness.tabs.canDrop(intoFolder: made.id) && !harness.tabs.dropDragged(intoFolder: made.id))
        _ = harness.tabs.itemProvider(for: .entry(made.id))
        #expect(!harness.tabs.canDrop(intoFolder: made.id))
    }

    @Test func `deleting a folder deletes what it holds, stopping what is open, and the window shows its own tab`()
        throws
    {
        let harness = window(3)
        let tab = harness.tabs.workspace.items[0]
        let content = try #require(harness.content(tab.focused))
        harness.tabs.newFolder(with: tab.id)
        let made = try #require(folder(harness))
        harness.tabs.select(entry: try #require(made.children.first?.id))
        harness.tabs.delete(folder: made.id)
        #expect(harness.tabs.favorites.isEmpty && content.stopped)
        #expect(harness.tabs.workspace.selectedEntry == nil && harness.tabs.shownItem != nil)
    }

    @Test func `deleting a folder with a running command asks twice`() throws {
        let harness = window(2)
        let tab = harness.tabs.workspace.items[0]
        let content = try #require(harness.content(tab.focused))
        content.closeWarning = "make is running"
        harness.tabs.newFolder(with: tab.id)
        let made = try #require(folder(harness))
        harness.tabs.delete(folder: made.id)
        #expect(!content.stopped && folder(harness) != nil)
        harness.tabs.delete(folder: made.id)
        #expect(content.stopped && folder(harness) == nil)
    }
}
