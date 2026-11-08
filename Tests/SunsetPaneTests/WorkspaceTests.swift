import Foundation
import Testing

@testable import SunsetPane

@Suite("Workspace: tabs") struct WorkspaceTests {
    /// A workspace of `count` single-pane tabs; the last is selected.
    private func workspace(_ count: Int) -> Workspace {
        var workspace = Workspace()
        for _ in 0 ..< count { workspace.add() }
        return workspace
    }

    private func ids(_ workspace: Workspace) -> [Workspace.ItemID] { workspace.items.map(\.id) }

    @Test func `an empty workspace has no selection, and the first tab added is selected with its pane focused`() {
        var workspace = Workspace()
        #expect(workspace.isEmpty && workspace.selectedID == nil && workspace.selectedIndex == nil)
        #expect(workspace.selectedPane == nil)
        let added = workspace.add()
        #expect(workspace.selectedID == added.item && workspace.count == 1)
        #expect(workspace.selectedPane == added.pane && workspace.items[0].panes == [added.pane])
    }

    @Test func `a new tab goes after the selected one and becomes selected`() {
        var workspace = workspace(3)
        let first = ids(workspace)[0]
        workspace.select(item: first)
        let new = workspace.add()
        #expect(ids(workspace).count == 4 && ids(workspace)[1] == new.item)
        #expect(workspace.selectedID == new.item)
    }

    @Test func `a new tab can go at the end instead`() {
        var workspace = workspace(3)
        workspace.select(index: 0)
        let new = workspace.add(after: .end)
        #expect(ids(workspace).last == new.item)
    }

    @Test func `closing the selected tab selects its right neighbour, or the left one at the end`() {
        var workspace = workspace(3)
        let all = ids(workspace)
        workspace.select(index: 1)
        let closed = workspace.close(item: all[1])
        #expect(ids(workspace) == [all[0], all[2]] && workspace.selectedIndex == 1)
        #expect(closed.count == 1)
        workspace.close(item: all[2])
        #expect(ids(workspace) == [all[0]] && workspace.selectedIndex == 0)
        workspace.close(item: all[0])
        #expect(workspace.isEmpty && workspace.selectedID == nil)
    }

    @Test func `closing a tab that is not selected keeps the selection on the same tab`() {
        var workspace = workspace(3)
        let all = ids(workspace)
        workspace.select(index: 2)
        workspace.close(item: all[0])
        #expect(workspace.selectedID == all[2] && workspace.selectedIndex == 1)
    }

    @Test func `next and previous wrap around`() {
        var workspace = workspace(3)
        workspace.select(index: 2)
        workspace.selectNext()
        #expect(workspace.selectedIndex == 0)
        workspace.selectPrevious()
        #expect(workspace.selectedIndex == 2)
        var one = self.workspace(1)
        one.selectNext()
        #expect(one.selectedIndex == 0)
        var none = Workspace()
        none.selectNext()
        #expect(none.selectedID == nil)
    }

    @Test func `a tab moves to a place, the selection stays on the same tab, and a place outside is brought inside`() {
        var workspace = workspace(4)
        let all = ids(workspace)
        workspace.select(item: all[1])
        workspace.move(item: all[3], to: 0)
        #expect(ids(workspace) == [all[3], all[0], all[1], all[2]] && workspace.selectedID == all[1])
        workspace.move(item: all[3], to: 99)
        #expect(ids(workspace) == [all[0], all[1], all[2], all[3]])
        workspace.move(item: all[0], to: -5)
        #expect(ids(workspace) == all)
    }

    @Test func `selecting or closing something that is not there changes nothing`() {
        var workspace = workspace(2)
        workspace.select(index: 1)
        workspace.select(index: 9)
        workspace.select(index: -1)
        workspace.select(item: Workspace.ItemID())
        workspace.focus(pane: PaneID())
        #expect(workspace.selectedIndex == 1)
        #expect(workspace.close(item: Workspace.ItemID()).isEmpty)
        #expect(workspace.count == 2)
    }

    @Test func `closing all but one keeps that one selected, and says which panes went`() {
        var workspace = workspace(3)
        let all = ids(workspace)
        let went = workspace.closeOthers(than: all[1])
        #expect(ids(workspace) == [all[1]] && workspace.selectedID == all[1])
        #expect(went.count == 2)
    }

    @Test func `every pane is found with the tab that holds it`() {
        let workspace = workspace(3)
        let panes = workspace.allPanes
        #expect(panes.count == 3 && Set(panes).count == 3)
        for (index, pane) in panes.enumerated() {
            #expect(workspace.item(containing: pane)?.id == ids(workspace)[index])
        }
        #expect(workspace.item(containing: PaneID()) == nil)
    }
}
