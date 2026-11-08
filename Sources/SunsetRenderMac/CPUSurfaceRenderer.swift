public import IOSurface
public import SunsetCore
public import SunsetRender

/// The CPU renderer behind `IOSurfaceRenderer`: `FrameRenderer` (an actor of its own) draws, `IOSurfacePresenter` keeps the frames in surfaces.
public final class CPUSurfaceRenderer: IOSurfaceRenderer {
    private let renderer: FrameRenderer
    private let presenter = IOSurfacePresenter()

    public init(metrics: RenderMetrics, glyphs: any GlyphSource, ligatures: Bool) {
        renderer = FrameRenderer(metrics: metrics, glyphs: glyphs, ligatures: ligatures)
    }

    public var cellMetrics: RenderMetrics { renderer.cellMetrics }
    public var latest: IOSurface? { presenter.latest }
    public var backend: RendererBackend { .cpu }
    public var hasFailed: Bool { false }

    public func present(_ screen: Screen, cursorVisible: Bool, textBlinkVisible: Bool, view: FrameView) async -> Bool {
        await renderer.present(
            screen,
            cursorVisible: cursorVisible,
            textBlinkVisible: textBlinkVisible,
            view: view,
            to: presenter
        )
    }
}
