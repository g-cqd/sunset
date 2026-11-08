import Foundation
import Testing

@testable import SunsetPane

@Suite("Workspace: splits") struct WorkspaceSplitTests {
    /// Three single-pane tabs; the last is selected.
    private func three() -> (workspace: Workspace, panes: [PaneID], items: [Workspace.ItemID]) {
        var workspace = Workspace()
        for _ in 0 ..< 3 { workspace.add() }
        return (workspace, workspace.allPanes, workspace.items.map(\.id))
    }

    @Test func `a new pane beside the focused one makes the tab a split and takes the focus`() throws {
        var (workspace, panes, items) = three()
        let newPane = workspace.addPane(beside: panes[2], edge: .right)
        let new = try #require(newPane)
        #expect(workspace.count == 3 && workspace.items[2].panes == [panes[2], new])
        #expect(workspace.items[2].isSplit && workspace.selectedPane == new && workspace.selectedID == items[2])
    }

    @Test func `a new pane beside a pane that is not there is refused`() throws {
        var (workspace, _, _) = three()
        #expect(workspace.addPane(beside: PaneID(), edge: .left) == nil)
        #expect(workspace.allPanes.count == 3)
    }

    @Test func `dropping a tab on a pane edge puts all its panes in that pane's tab, which is selected`() throws {
        var (workspace, panes, items) = three()
        workspace.drop(item: items[0], onto: panes[2], edge: .left)
        #expect(workspace.count == 2 && workspace.items.map(\.id) == [items[1], items[2]])
        #expect(
            workspace.items[1].layout
                == .split(.horizontal, ratio: 0.5, first: .pane(panes[0]), second: .pane(panes[2]))
        )
        #expect(workspace.selectedID == items[2] && workspace.selectedPane == panes[0])
    }

    @Test func `dropping a tab that is itself split brings its whole layout`() throws {
        var (workspace, panes, items) = three()
        let extraPane = workspace.addPane(beside: panes[2], edge: .bottom)
        let extra = try #require(extraPane)
        workspace.drop(item: items[2], onto: panes[0], edge: .right)
        #expect(workspace.count == 2)
        #expect(workspace.items[0].panes == [panes[0], panes[2], extra])
        #expect(workspace.selectedID == items[0])
    }

    @Test func `a tab cannot be dropped on itself, nor on a pane that is not there`() throws {
        var (workspace, panes, items) = three()
        let before = workspace
        workspace.drop(item: items[1], onto: panes[1], edge: .left)
        workspace.drop(item: items[1], onto: PaneID(), edge: .left)
        workspace.drop(item: Workspace.ItemID(), onto: panes[1], edge: .left)
        #expect(workspace == before)
    }

    @Test func `moving a pane out of a split into another tab leaves the split's other panes where they were`() throws {
        var (workspace, panes, items) = three()
        let extraPane = workspace.addPane(beside: panes[2], edge: .right)
        let extra = try #require(extraPane)
        workspace.movePane(extra, beside: panes[0], edge: .top)
        #expect(workspace.items[0].panes == [extra, panes[0]])
        #expect(workspace.items[2].panes == [panes[2]] && !workspace.items[2].isSplit)
        #expect(workspace.selectedID == items[0] && workspace.selectedPane == extra)
    }

    @Test func `moving a pane to another place in its own tab rearranges that tab`() throws {
        var (workspace, panes, _) = three()
        let bPane = workspace.addPane(beside: panes[2], edge: .right)
        let b = try #require(bPane)
        let cPane = workspace.addPane(beside: b, edge: .right)
        let c = try #require(cPane)
        workspace.movePane(c, beside: panes[2], edge: .left)
        #expect(workspace.items[2].panes == [c, panes[2], b])
        #expect(workspace.count == 3)
    }

    @Test func `moving the only pane of a tab beside another removes the empty tab`() throws {
        var (workspace, panes, items) = three()
        workspace.movePane(panes[1], beside: panes[0], edge: .bottom)
        #expect(workspace.items.map(\.id) == [items[0], items[2]])
        #expect(workspace.items[0].panes == [panes[0], panes[1]])
    }

    @Test
    func
        `closing a pane of a split leaves the tab, its space goes to the sibling and the focus to a pane that is left`()
        throws
    {
        var (workspace, panes, items) = three()
        let bPane = workspace.addPane(beside: panes[2], edge: .right)
        let b = try #require(bPane)
        workspace.close(pane: b)
        #expect(workspace.items[2].panes == [panes[2]] && workspace.selectedPane == panes[2])
        #expect(workspace.selectedID == items[2] && workspace.count == 3)
    }

    @Test func `closing the only pane of a tab closes the tab`() throws {
        var (workspace, panes, items) = three()
        workspace.close(pane: panes[2])
        #expect(workspace.items.map(\.id) == [items[0], items[1]] && workspace.selectedID == items[1])
        workspace.close(pane: PaneID())
        #expect(workspace.count == 2)
    }

    @Test func `a pane taken out of a split becomes a tab of its own right after it, selected`() throws {
        var (workspace, panes, items) = three()
        let bPane = workspace.addPane(beside: panes[1], edge: .right)
        let b = try #require(bPane)
        workspace.select(index: 0)
        workspace.detach(pane: b)
        #expect(workspace.count == 4 && workspace.items[1].id == items[1] && workspace.items[1].panes == [panes[1]])
        #expect(workspace.items[2].panes == [b] && workspace.selectedID == workspace.items[2].id)
        workspace.detach(pane: panes[0])
        #expect(workspace.count == 4, "a pane alone in its tab stays where it is")
    }

    @Test func `focus moves between the panes of the selected tab, going round`() throws {
        var (workspace, panes, _) = three()
        let bPane = workspace.addPane(beside: panes[2], edge: .right)
        let b = try #require(bPane)
        workspace.focusNext()
        #expect(workspace.selectedPane == panes[2])
        workspace.focusNext()
        #expect(workspace.selectedPane == b)
        workspace.focusPrevious()
        #expect(workspace.selectedPane == panes[2])
    }

    @Test func `focusing a pane selects its tab`() throws {
        var (workspace, panes, items) = three()
        _ = workspace.addPane(beside: panes[2], edge: .right)
        workspace.focus(pane: panes[0])
        #expect(workspace.selectedID == items[0] && workspace.selectedPane == panes[0])
    }

    @Test func `a divider's ratio is set on the tab that has it`() throws {
        var (workspace, panes, items) = three()
        _ = workspace.addPane(beside: panes[2], edge: .right)
        workspace.setRatio(0.3, at: [], in: items[2])
        #expect(workspace.items[2].layout.ratio(at: []) == 0.3)
        workspace.setRatio(0.3, at: [], in: Workspace.ItemID())
        #expect(workspace.items[0].layout.ratio(at: []) == nil)
    }
}
