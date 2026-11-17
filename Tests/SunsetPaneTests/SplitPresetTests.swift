import CoreGraphics
import Foundation
import Testing

@testable import SunsetPane

/// The fourth light's presets (n78, t287; the owner's answers of 2026-11-17): side by side, stacked, three columns, one large
/// and two stacked, a 2×2 grid. With too few panes the next tabs join as panes; with too many, the extra panes become tabs.
@Suite("Split presets") struct SplitPresetTests {
    /// A window of `count` one-pane tabs, the first selected.
    private func window(_ count: Int) -> (Workspace, [PaneID]) {
        var workspace = Workspace()
        var panes: [PaneID] = []
        for _ in 0 ..< count { panes.append(workspace.add(after: .end).pane) }
        workspace.select(index: 0)
        return (workspace, panes)
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
        #expect(SplitPreset.allCases.map(\.paneCount) == [2, 2, 3, 3, 4])
    }

    @Test func `with too few panes the next tabs join, in their order`() throws {
        var (workspace, panes) = window(4)
        let first = try #require(workspace.items.first?.id)
        let applied = workspace.apply(.grid, to: first)
        #expect(applied)
        #expect(workspace.items.count == 1 && workspace.items[0].panes == panes)
        #expect(workspace.selectedID == first)
    }

    @Test func `with too many panes the extra ones become tabs after it`() throws {
        var (workspace, panes) = window(4)
        let first = try #require(workspace.items.first?.id)
        workspace.apply(.grid, to: first)
        let applied = workspace.apply(.sideBySide, to: first)
        #expect(applied)
        #expect(workspace.items.map(\.panes) == [[panes[0], panes[1]], [panes[2]], [panes[3]]])
    }

    @Test func `without enough tabs nothing changes`() throws {
        var (workspace, _) = window(2)
        let before = workspace
        let first = try #require(workspace.items.first?.id)
        let applied = workspace.apply(.threeColumns, to: first)
        #expect(!applied)
        #expect(workspace == before)
    }
}
