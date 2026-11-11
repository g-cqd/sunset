import SunsetRender
import SunsetRenderMac

extension TerminalModel {
    package func currentGrid() -> GridSize? {
        guard viewPixels.width > 0, viewPixels.height > 0, let metrics = renderer?.cellMetrics else { return nil }
        return GridSize(
            columns: max(2, (viewPixels.width - 2 * paddingPixels) / metrics.cellWidth),
            rows: max(1, (viewPixels.height - 2 * paddingPixels - metrics.topInset) / metrics.cellHeight)
        )
    }
}
