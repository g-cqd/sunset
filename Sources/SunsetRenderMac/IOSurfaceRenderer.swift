public import IOSurface
public import SunsetCore
public import SunsetRender

/// What the window needs of a renderer that draws into `IOSurface`s its layer shows: the cell metrics, a frame per call, and the surface that holds the latest
/// frame. The CPU renderer and the Metal one both are one (ADR-0024: backends are interchangeable at run time).
public protocol IOSurfaceRenderer: AnyObject, Sendable {
    /// The cell size and padding this renderer draws with.
    var cellMetrics: RenderMetrics { get }

    /// The surface that holds the latest frame; nil before the first.
    var latest: IOSurface? { get }

    /// Which backend this is, for the user and the logs: `cpu` or `gpu`.
    var backend: RendererBackend { get }

    /// The renderer could not draw a frame (the GPU was lost, a command failed): the window should use another one. Never true for the CPU renderer.
    var hasFailed: Bool { get }

    /// Draws `screen` (a snapshot: its dirty rows are what changed since the frame before). Returns whether anything changed (when nothing did, `latest` is the
    /// same surface as before).
    func present(_ screen: Screen, cursorVisible: Bool, textBlinkVisible: Bool, view: FrameView) async -> Bool

    /// No frame is coming for now (the terminal is quiet, or not shown): lets go of what is only needed while frames come.
    /// The frame on screen stays. The next `present` makes again what it needs.
    /// - Returns: false when something could not be let go yet (the window server still held it): worth asking again.
    @discardableResult func rest() async -> Bool
}

extension IOSurfaceRenderer {
    @discardableResult public func rest() async -> Bool { true }
}
