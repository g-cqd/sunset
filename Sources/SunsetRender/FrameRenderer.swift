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
        view: FrameView = FrameView()
    ) -> RenderedFrame {
        let drawn = draw(screen, cursorVisible: cursorVisible, textBlinkVisible: textBlinkVisible, view: view)
        let result = RenderedFrame(width: drawn.width, height: drawn.height, bytes: drawn.rgbaBytes)
        surface = drawn
        return result
    }

    /// Draws `screen` and hands the presenter the pixel rows that changed, in place of returning the frame as bytes. Returns whether anything changed (when
    /// nothing did, the presenter is not called).
    public func present(
        _ screen: Screen,
        cursorVisible: Bool,
        textBlinkVisible: Bool,
        view: FrameView = FrameView(),
        to presenter: some FramePresenter
    ) -> Bool {
        let drawn = draw(screen, cursorVisible: cursorVisible, textBlinkVisible: textBlinkVisible, view: view)
        defer { surface = drawn }
        guard let rows = renderer.changedPixelRows else { return false }
        presenter.present(drawn, changedRows: rows)
        return true
    }

    private func draw(_ screen: Screen, cursorVisible: Bool, textBlinkVisible: Bool, view: FrameView) -> Surface {
        let grid = metrics.surfaceSize(columns: screen.columns, rows: screen.rows)
        let pixels = (width: grid.width + view.extraWidth, height: grid.height + view.extraHeight)
        if surface == nil || size?.columns != screen.columns || size?.rows != screen.rows
            || surface?.width != pixels.width || surface?.height != pixels.height
        {
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
            view: view
        )
        return drawn
    }
}
