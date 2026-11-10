import CoreGraphics
import Foundation
import SunsetPane
import Testing

@Suite("Tab drop action") struct TabDropActionTests {
    @Test func `the top and bottom quarters reorder before or after the row, and the middle half splits left or right`()
    {
        #expect(TabDropAction.resolve(at: CGPoint(x: 20, y: 4), in: CGSize(width: 200, height: 32)) == .moveBefore)
        #expect(TabDropAction.resolve(at: CGPoint(x: 180, y: 30), in: CGSize(width: 200, height: 32)) == .moveAfter)
        #expect(TabDropAction.resolve(at: CGPoint(x: 40, y: 16), in: CGSize(width: 200, height: 32)) == .split(.left))
        #expect(TabDropAction.resolve(at: CGPoint(x: 150, y: 16), in: CGSize(width: 200, height: 32)) == .split(.right))
    }

    @Test func `applying a move or split updates the workspace, and dropping a tab on itself does nothing`() {
        var workspace = Workspace()
        let first = workspace.add()
        let second = workspace.add()
        let third = workspace.add()

        // Move third before first (index 0).
        workspace.applyTabDrop(.item(third.item), onto: first.item, action: .moveBefore)
        #expect(workspace.items.map(\.id) == [third.item, first.item, second.item])

        // Move third after first (so order becomes first, third, second).
        workspace.applyTabDrop(.item(third.item), onto: first.item, action: .moveAfter)
        #expect(workspace.items.map(\.id) == [first.item, third.item, second.item])

        // Dropping a tab on itself changes nothing.
        let unchanged = workspace
        workspace.applyTabDrop(.item(first.item), onto: first.item, action: .split(.right))
        #expect(workspace == unchanged)

        // Splitting second onto first's right merges second into first.
        workspace.applyTabDrop(.item(second.item), onto: first.item, action: .split(.right))
        #expect(workspace.items.map(\.id) == [first.item, third.item])
        #expect(workspace.items[0].panes == [first.pane, second.pane])
        #expect(workspace.selectedPane == second.pane)
    }

    @Test
    func `dropping a pane from a split onto another tab row moves it into that tab or detaches it before or after`() {
        var workspace = Workspace()
        let first = workspace.add()
        let extra = try #require(workspace.addPane(beside: first.pane, edge: .right))
        let second = workspace.add()

        // Split: move `extra` from `first` onto the left of `second`.
        workspace.applyTabDrop(.pane(extra), onto: second.item, action: .split(.left))
        #expect(workspace.items.count == 2)
        #expect(workspace.items[0].panes == [first.pane])
        #expect(workspace.items[1].panes == [extra, second.pane])

        // Move before: detach `extra` from `second` into its own tab before `first`.
        workspace.applyTabDrop(.pane(extra), onto: first.item, action: .moveBefore)
        #expect(workspace.items.count == 3)
        #expect(workspace.items[0].panes == [extra])
        #expect(workspace.items[1].panes == [first.pane])
        #expect(workspace.items[2].panes == [second.pane])
    }
}
