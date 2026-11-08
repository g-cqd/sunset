import SunsetCore
import SunsetRender

extension TerminalModel {
    /// The pixels the view has beyond the surface of `screen`'s grid (the part of a cell the window's size leaves over): the renderer paints them with the
    /// background, so that the terminal's colour reaches the edges of the view instead of a strip of black.
    func extraPixels(for screen: Screen) -> (width: Int, height: Int) {
        guard let metrics = renderer?.cellMetrics else { return (0, 0) }
        let grid = metrics.surfaceSize(columns: screen.columns, rows: screen.rows)
        return (max(viewPixels.width - grid.width, 0), max(viewPixels.height - grid.height, 0))
    }
}
