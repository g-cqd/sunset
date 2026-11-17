import CoreGraphics
import Foundation
import Testing

@testable import SunsetPane

/// A tab menu's layouts (n78, t287; the owner, 2026-11-17): side by side, stacked, three columns, one large and two stacked,
/// a 2×2 grid; offered for several tabs selected or one split tab, only those of as many panes as they hold.
@Suite("Split presets") struct SplitPresetTests {
    /// A window of `count` one-pane tabs.
    private func window(_ count: Int) -> Workspace {
        var workspace = Workspace()
        for _ in 0 ..< count { workspace.add(after: .end) }
        return workspace
    }

    @Test func `each preset lays out its number of panes in its shape`() {
        let p = (0 ..< 4).map { _ in PaneID() }
        #expect(
            SplitPreset.sideBySide.layout(of: p)
                == .split(.horizontal, ratio: 0.5, first: .pane(p[0]), second: .pane(p[1]))
        )
        #expect(
            SplitPreset.stacked.layout(of: p) == .split(.vertical, ratio: 0.5, first: .pane(p[0]), second: .pane(p[1]))
        )
        #expect(SplitPreset.threeColumns.layout(of: p).panes == Array(p.prefix(3)))
        #expect(SplitPreset.grid.layout(of: p).panes == p)
        let frames = SplitPreset.largeAndTwoStacked.layout(of: p)
            .frames(in: CGRect(x: 0, y: 0, width: 100, height: 100))
        #expect(frames[p[0]]?.height == 100 && frames[p[1]]?.height == 50 && frames[p[2]]?.height == 50)
        let columns = SplitPreset.threeColumns.layout(of: p).frames(in: CGRect(x: 0, y: 0, width: 90, height: 10))
        #expect(p.prefix(3).allSatisfy { abs((columns[$0]?.width ?? 0) - 30) < 0.001 })
    }

    @Test func `only the presets of as many panes as the tabs hold are offered`() {
        let workspace = window(4)
        let ids = workspace.items.map(\.id)
        #expect(workspace.presets(for: Array(ids.prefix(2))) == [.sideBySide, .stacked])
        #expect(workspace.presets(for: Array(ids.prefix(3))) == [.threeColumns, .largeAndTwoStacked])
        #expect(workspace.presets(for: ids) == [.grid])
        #expect(workspace.presets(for: [Workspace.ItemID()]).isEmpty)
    }

    @Test func `the selected tabs become one, where the first was, in the sidebar's order`() {
        var workspace = window(4)
        let ids = workspace.items.map(\.id)
        let panes = workspace.items.map { $0.panes[0] }
        let applied = workspace.apply(.threeColumns, to: [ids[3], ids[1], ids[2]])
        #expect(applied)
        #expect(workspace.items.map(\.id) == [ids[0], ids[1]])
        #expect(workspace.items[1].panes == [panes[1], panes[2], panes[3]])
        #expect(workspace.selectedID == ids[1])
    }

    @Test func `a split tab is laid out again; a preset that does not fit changes nothing`() {
        var workspace = window(2)
        let ids = workspace.items.map(\.id)
        workspace.apply(.sideBySide, to: ids)
        let split = workspace.items[0].id
        let stacked = workspace.apply(.stacked, to: [split])
        #expect(stacked && workspace.items[0].layout.panes.count == 2)
        let before = workspace
        let grid = workspace.apply(.grid, to: [split])
        #expect(!grid && workspace == before)
    }
}
