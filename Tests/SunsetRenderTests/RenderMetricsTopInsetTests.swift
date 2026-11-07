import Testing

@testable import SunsetRender

/// Extra space above the grid only (the strip of a window with no title bar that drags it).
@Suite("Render metrics: top inset") struct RenderMetricsTopInsetTests {
    private func metrics() -> RenderMetrics {
        var metrics = RenderMetrics(cellWidth: 10, cellHeight: 20)
        metrics.paddingX = 8
        metrics.paddingY = 4
        metrics.topInset = 30
        return metrics
    }

    @Test func `the surface is taller by the inset, once`() {
        #expect(metrics().surfaceSize(columns: 80, rows: 24).height == 24 * 20 + 2 * 4 + 30)
        #expect(metrics().surfaceSize(columns: 80, rows: 24).width == 80 * 10 + 2 * 8)
    }

    @Test func `the grid starts below the padding and the inset`() {
        let metrics = metrics()
        #expect(metrics.cell(atPixelX: 8, pixelY: 4 + 30, columns: 80, rows: 24).row == 0)
        #expect(metrics.cell(atPixelX: 8, pixelY: 4 + 30 + 20, columns: 80, rows: 24).row == 1)
        #expect(metrics.cell(atPixelX: 8, pixelY: 10, columns: 80, rows: 24).row == 0, "in the inset: the nearest row")
        #expect(metrics.gridPixel(x: 8, y: 4 + 30 + 7, columns: 80, rows: 24).y == 7)
    }

    @Test func `a glyph in the first row is drawn below the inset`() {
        var inset = RenderMetrics(cellWidth: 8, cellHeight: 16)
        inset.topInset = 24
        var rig = CPURendererRig(10, 4, metrics: inset)
        rig.frame("a", cursorVisible: false)
        #expect(rig.surface.height == 4 * 16 + 24)
        // Rows above the inset are background; the box glyph (2 px inside its cell) starts at 24 + 2.
        #expect(rig.surface[3, 5] == black)
        #expect(rig.surface[3, 24 + 5] == white)
        #expect(rig.surface[3, 24 + 15] == black)
    }
}
