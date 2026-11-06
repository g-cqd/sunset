public import SunsetCore

/// A CPU renderer on an actor of its own: the rendering happens off the main thread, one frame at a time, and the presenter gets a plain value back. It
/// keeps its surface and its caches between frames (the renderer draws only what changed), and starts again when the screen's size changes.
public actor FrameRenderer {
    private let renderer: CPURenderer
    private let metrics: RenderMetrics
    private var surface: Surface?
    private var size: (columns: Int, rows: Int)?

    public init(metrics: RenderMetrics, glyphs: any GlyphSource, ligatures: Bool = false) {
        self.metrics = metrics
        renderer = CPURenderer(metrics: metrics, glyphs: glyphs, ligatures: ligatures)
    }

    /// The cell size and padding this renderer draws with.
    public nonisolated var cellMetrics: RenderMetrics { metrics }

    /// Draws `screen` (a snapshot: its dirty rows are what changed since the frame before) and returns the whole surface.
    public func frame(
        for screen: Screen,
        cursorVisible: Bool,
        textBlinkVisible: Bool,
        scrolledBack: Int = 0,
        selection: Selection? = nil
    ) -> RenderedFrame {
        let pixels = metrics.surfaceSize(columns: screen.columns, rows: screen.rows)
        if surface == nil || size?.columns != screen.columns || size?.rows != screen.rows {
            surface = Surface(width: pixels.width, height: pixels.height)
            size = (screen.columns, screen.rows)
            renderer.invalidate()
        }
        var drawn = surface ?? Surface(width: pixels.width, height: pixels.height)
        surface = nil
        renderer.render(
            screen,
            into: &drawn,
            cursorVisible: cursorVisible,
            textBlinkVisible: textBlinkVisible,
            scrolledBack: scrolledBack,
            selection: selection
        )
        let result = RenderedFrame(width: drawn.width, height: drawn.height, bytes: drawn.rgbaBytes)
        surface = drawn
        return result
    }
}
