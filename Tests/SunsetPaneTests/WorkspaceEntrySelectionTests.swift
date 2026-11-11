import Foundation
import Testing

@testable import SunsetPane

@Suite("Workspace: a kept entry selected in a window") struct WorkspaceEntrySelectionTests {
    private func workspace() -> Workspace {
        var workspace = Workspace()
        workspace.add()
        workspace.add()
        return workspace
    }

    @Test func `selecting an entry keeps the window's own selected tab behind it`() {
        var workspace = workspace()
        let tab = workspace.selectedID
        let entry = Favorites.NodeID()
        workspace.select(entry: entry)
        #expect(workspace.selectedEntry == entry && workspace.selectedID == tab)
        workspace.select(entry: nil)
        #expect(workspace.selectedEntry == nil && workspace.selectedID == tab)
    }

    @Test func `selecting, adding, stepping to or focusing a tab leaves the entry`() {
        let entry = Favorites.NodeID()
        var selected = workspace()
        selected.select(entry: entry)
        selected.select(index: 0)
        var added = workspace()
        added.select(entry: entry)
        added.add()
        var next = workspace()
        next.select(entry: entry)
        next.selectNext()
        var previous = workspace()
        previous.select(entry: entry)
        previous.selectPrevious()
        var focused = workspace()
        focused.select(entry: entry)
        focused.focus(pane: focused.items[0].focused)
        var byID = workspace()
        byID.select(entry: entry)
        byID.select(item: byID.items[0].id)
        for workspace in [selected, added, next, previous, focused, byID] { #expect(workspace.selectedEntry == nil) }
    }

    @Test func `closing a tab does not leave the entry, and the selection is saved with the workspace`() throws {
        var workspace = workspace()
        let entry = Favorites.NodeID()
        workspace.select(entry: entry)
        workspace.close(item: workspace.items[0].id)
        #expect(workspace.selectedEntry == entry)
        let read = try JSONDecoder().decode(Workspace.self, from: JSONEncoder().encode(workspace))
        #expect(read == workspace)
    }

    @Test func `a tab is taken out whole and put back at a place, without its panes being closed`() throws {
        var workspace = workspace()
        let first = workspace.items[0]
        let out = workspace.take(item: first.id)
        let taken = try #require(out)
        #expect(taken == first && workspace.count == 1 && workspace.selectedID == workspace.items[0].id)
        #expect(workspace.take(item: first.id) == nil)
        workspace.insert(taken, at: 1)
        #expect(workspace.items.map(\.id).last == first.id && workspace.selectedID == first.id)
        workspace.insert(taken, at: 0)
        #expect(workspace.count == 2, "a tab already there is not put twice")
    }
}
