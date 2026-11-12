import Testing

@testable import SunsetPane

@Suite("Workspace: a tab added at a place") struct WorkspaceAddTabTests {
    @Test func `a tab added at a place, shown or not; with nothing selected it is selected`() {
        var workspace = Workspace()
        let first = workspace.add()
        workspace.add()
        let hidden = workspace.addTab(at: 1, show: false)
        #expect(workspace.items[1].panes == [hidden] && workspace.selectedIndex == 2)
        let shown = workspace.addTab(at: 99, show: true)
        #expect(workspace.items.last?.panes == [shown] && workspace.selectedPane == shown)
        var empty = Workspace()
        let only = empty.addTab(at: 0, show: false)
        #expect(empty.selectedPane == only && first.pane != only)
    }
}
