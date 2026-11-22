import SunsetHost
import SunsetRender
import SunsetRenderMac

extension TerminalModel {
    package func currentGrid() -> GridSize? {
        guard viewPixels.width > 0, viewPixels.height > 0, let metrics = renderer?.cellMetrics else { return nil }
        return GridSize(
            columns: max(2, (viewPixels.width - 2 * paddingPixels) / metrics.cellWidth),
            rows: max(1, (viewPixels.height - 2 * paddingPixels - metrics.topInset) / metrics.cellHeight),
            cellWidth: metrics.cellWidth,
            cellHeight: metrics.cellHeight
        )
    }

    /// Tells `session` its new grid, and a cell's size in pixels, which programs size their images by (ADR-0117).
    static func resize(_ session: TerminalSession, to size: GridSize) async {
        await session.resize(
            columns: size.columns,
            rows: size.rows,
            cellWidth: size.cellWidth,
            cellHeight: size.cellHeight
        )
    }
}
