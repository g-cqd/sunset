import Testing

@testable import SunsetRender

@Suite("Render metrics") struct RenderMetricsTests {
    private func metrics() -> RenderMetrics {
        var metrics = RenderMetrics(cellWidth: 10, cellHeight: 20)
        metrics.paddingX = 8
        metrics.paddingY = 4
        return metrics
    }

    @Test func `a pixel inside the grid is in the cell that covers it`() {
        let cell = metrics().cell(atPixelX: 8, pixelY: 4, columns: 80, rows: 24)
        #expect(cell.column == 0 && cell.row == 0)
        let inner = metrics().cell(atPixelX: 8 + 10 * 5 + 9, pixelY: 4 + 20 * 3 + 19, columns: 80, rows: 24)
        #expect(inner.column == 5 && inner.row == 3)
    }

    @Test func `a pixel in the padding or outside the grid is the nearest edge cell`() {
        let metrics = metrics()
        let before = metrics.cell(atPixelX: -50, pixelY: 1, columns: 80, rows: 24)
        #expect(before.column == 0 && before.row == 0)
        let past = metrics.cell(atPixelX: 5000, pixelY: 5000, columns: 80, rows: 24)
        #expect(past.column == 79 && past.row == 23)
    }

    @Test func `the pixel offset inside the grid leaves out the padding`() {
        let offset = metrics().gridPixel(x: 108, y: 64, columns: 80, rows: 24)
        #expect(offset.x == 100 && offset.y == 60)
    }
}
