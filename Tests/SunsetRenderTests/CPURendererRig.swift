import SunsetCore
import Testing

@testable import SunsetRender

/// A terminal, a renderer with box glyphs and a surface the size of the grid.
struct CPURendererRig {
    var terminal: Terminal
    var surface: Surface
    let renderer: CPURenderer

    init(
        _ columns: Int = 10,
        _ rows: Int = 4,
        glyphs: any GlyphSource = BoxGlyphSource(),
        metrics: RenderMetrics = metrics
    ) {
        terminal = Terminal(columns: columns, rows: rows)
        let size = metrics.surfaceSize(columns: columns, rows: rows)
        surface = Surface(width: size.width, height: size.height)
        renderer = CPURenderer(metrics: metrics, glyphs: glyphs)
    }

    /// Feeds text and draws a frame (and clears the dirty marks, as a host does).
    mutating func frame(
        _ text: String = "",
        cursorVisible: Bool = true,
        scrolledBack: Int = 0,
        selection: Selection? = nil,
        hoveredLink: UInt16 = 0
    ) {
        terminal.feed(text)
        renderer.render(
            terminal.screen,
            into: &surface,
            cursorVisible: cursorVisible,
            view: FrameView(scrolledBack: scrolledBack, selection: selection, hoveredLink: hoveredLink)
        )
        terminal.clearDirty()
    }

    /// The colour at a pixel inside the cell (row, column).
    func pixel(row: Int, column: Int, x: Int, y: Int) -> RGB {
        surface[column * metrics.cellWidth + x, row * metrics.cellHeight + y]
    }
}
