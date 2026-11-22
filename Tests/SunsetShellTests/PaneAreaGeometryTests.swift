import Testing

@testable import SunsetShell
@testable import SunsetShellModel

/// "when coming back from full screen corners of the terminal are not rounded anymore. also in full screen, no border or
/// margin whatsoever should exist around the content area, unless sidebar is set to be fixed, then the sidebar should be
/// shown as usual but the content itself should span from top to bottom and edge to sidebar, only exception is if split tab
/// happens, if 2 tabs only vertically or horizontally we can go edge to edge with a small space between them …, but if we
/// have a grid like area, then we should bring back standard margin around the content areas and then keep a minimum corner
/// radius everywhere instead of 0".
@Suite("How the panes sit, in a window and in full screen") struct PaneAreaGeometryTests {
    private func make(fullScreen: Bool, docked: Bool = false, panes: Int, windowRadius: Double = 16) -> PaneAreaGeometry
    {
        .make(
            fullScreen: fullScreen,
            docked: docked,
            panes: panes,
            measures: .init(
                margin: 8,
                paneGap: 6,
                windowRadius: windowRadius,
                terminalRadius: nil,
                innerCornerRadius: 6
            )
        )
    }

    @Test
    func `in a window, as before: one pane flush, a split or a docked sidebar in cards concentric with the window`() {
        #expect(
            make(fullScreen: false, panes: 1) == .init(inset: 0, gap: 0, isCard: false, outerRadius: 16, innerRadius: 6)
        )
        #expect(
            make(fullScreen: false, panes: 2) == .init(inset: 6, gap: 6, isCard: true, outerRadius: 10, innerRadius: 6)
        )
        #expect(
            make(fullScreen: false, docked: true, panes: 1)
                == .init(inset: 8, gap: 8, isCard: true, outerRadius: 8, innerRadius: 6)
        )
    }

    @Test func `in full screen one pane fills it, docked sidebar or not, square`() {
        for docked in [false, true] {
            #expect(
                make(fullScreen: true, docked: docked, panes: 1, windowRadius: 0)
                    == .init(inset: 0, gap: 0, isCard: false, outerRadius: 0, innerRadius: 0)
            )
        }
    }

    @Test func `in full screen two panes go to the edges, a small space between, rounded only where they meet`() {
        #expect(
            make(fullScreen: true, panes: 2, windowRadius: 0)
                == .init(inset: 0, gap: 6, isCard: true, outerRadius: 0, innerRadius: 6)
        )
    }

    @Test func `in full screen a grid has the window's margins back and a radius everywhere, never 0`() {
        let grid = make(fullScreen: true, panes: 3, windowRadius: 0)
        #expect(grid == .init(inset: 6, gap: 6, isCard: true, outerRadius: 10, innerRadius: 6))
        #expect(make(fullScreen: true, docked: true, panes: 4, windowRadius: 0).inset == 8)
    }

    @Test func `the window's radius read as 0 (full screen, or not asked yet) never squares a window's cards`() {
        #expect(make(fullScreen: false, panes: 2, windowRadius: 0).outerRadius == 10, "the standard window's then")
    }
}
