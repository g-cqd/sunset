internal import CoreGraphics
public import IOSurface
internal import Metal
public import SunsetCore
public import SunsetRender
public import SunsetRenderMac
internal import Synchronization

/// The Metal renderer behind `IOSurfaceRenderer`: the CPU renderer works out the frame's operations (`CPURenderer.record`) and `MetalCompositor` draws them
/// straight into the next of three `IOSurface`s the layer shows (the one just shown is never written: the compositor may still be reading it). That surface
/// is first brought up to the one shown last, on the GPU: the rows it missed are copied from it, and a scroll's rows moved from it. No other texture keeps
/// the picture (renderer plan, item 5: a frame-sized canvas less per window).
public actor MetalSurfaceRenderer: IOSurfaceRenderer {
    public nonisolated let cellMetrics: RenderMetrics
    private let recorder: CPURenderer
    private let compositor: MetalCompositor
    private var ring: SurfaceRing?
    /// How long without frames lets the window's third surface go (`SurfaceRing`).
    private var quietAfter = Duration.seconds(1)
    private nonisolated let shown = Mutex<IOSurface?>(nil)
    private nonisolated let failed = Mutex(false)
    /// Whether a frame is being drawn, and the presents waiting for it to end, in order: the actor is free while the GPU draws (`present` suspends), so a
    /// second call may come in, and it must not touch the ring or the compositor before the first is done.
    private var drawing = false
    private var waiting: [CheckedContinuation<Void, Never>] = []

    /// nil when there is no Metal device.
    public init?(metrics: RenderMetrics, glyphs: any GlyphSource, ligatures: Bool) {
        guard let compositor = MetalCompositor() else { return nil }
        self.compositor = compositor
        cellMetrics = metrics
        recorder = CPURenderer(metrics: metrics, glyphs: glyphs, ligatures: ligatures)
    }

    /// How many frame-sized textures the window holds (for tests: memory, n11).
    var frameBufferCount: Int { ring?.slots.count ?? 0 }

    func setQuietAfter(_ duration: Duration) { quietAfter = duration }

    public nonisolated var latest: IOSurface? { shown.withLock { $0 } }
    public nonisolated var backend: RendererBackend { .gpu }
    public nonisolated var hasFailed: Bool { failed.withLock { $0 } }

    public func present(_ screen: Screen, cursorVisible: Bool, textBlinkVisible: Bool, view: FrameView) async -> Bool {
        await takeTurn()
        defer { endTurn() }
        return await draw(screen, cursorVisible: cursorVisible, textBlinkVisible: textBlinkVisible, view: view)
    }

    private func takeTurn() async {
        guard drawing else {
            drawing = true
            return
        }
        // The turn is handed over by `endTurn`, so `drawing` stays true and no newcomer slips in between.
        await withCheckedContinuation { waiting.append($0) }
    }

    private func endTurn() {
        if waiting.isEmpty {
            drawing = false
        } else {
            waiting.removeFirst().resume()
        }
    }

    private func draw(_ screen: Screen, cursorVisible: Bool, textBlinkVisible: Bool, view: FrameView) async -> Bool {
        let grid = cellMetrics.surfaceSize(columns: screen.columns, rows: screen.rows)
        let size = (width: grid.width + view.extraWidth, height: grid.height + view.extraHeight)
        if ring?.width != size.width || ring?.height != size.height {
            ring = SurfaceRing(device: compositor.device, width: size.width, height: size.height)
            recorder.invalidate()
        }
        guard var ring else {
            failed.withLock { $0 = true }
            return false
        }
        let frame = recorder.record(
            screen,
            width: size.width,
            height: size.height,
            cursorVisible: cursorVisible,
            textBlinkVisible: textBlinkVisible,
            view: view
        )
        let now = ContinuousClock.now
        guard let changed = frame.changedPixelRows, let target = ring.next(now: now, quiet: quietAfter) else {
            self.ring = ring
            return false
        }
        // Without a surface shown yet, the frame draws everything (the renderer was invalidated with the ring).
        let previous = ring.shown.map { ring.slots[$0].texture }
        let missing = ring.slots[target].missing.map { Self.rows($0, without: frame.move) } ?? []
        self.ring = ring
        do {
            try await compositor.apply(
                frame,
                to: ring.slots[target].texture,
                previous: previous,
                restoring: previous == nil ? [] : missing
            )
        } catch {
            // The frame was not drawn and the GPU may be gone: the window is told to use the CPU renderer.
            recorder.invalidate()
            failed.withLock { $0 = true }
            return false
        }
        ring.drawn(target, changed: changed, at: now)
        self.ring = ring
        let surface = ring.slots[target].surface
        shown.withLock { $0 = surface }
        return true
    }

    /// The rows of `rows` that `move` does not write: a surface brought up to date need not copy rows the move replaces.
    static func rows(_ rows: ClosedRange<Int>, without move: PixelMove?) -> [ClosedRange<Int>] {
        guard let move, move.height > 0 else { return [rows] }
        let moved = move.destinationY ... move.destinationY + move.height - 1
        var left: [ClosedRange<Int>] = []
        if rows.lowerBound < moved.lowerBound {
            left.append(rows.lowerBound ... min(rows.upperBound, moved.lowerBound - 1))
        }
        if rows.upperBound > moved.upperBound {
            left.append(max(rows.lowerBound, moved.upperBound + 1) ... rows.upperBound)
        }
        return left
    }
}
