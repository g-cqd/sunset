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
    private static let bufferCount = 3
    /// 'RGBA': the bytes of a pixel are red, green, blue, alpha, as the renderer packs them.
    private static let pixelFormat: Int32 = 0x5247_4241

    private struct Ring {
        var surfaces: [IOSurface] = []
        var textures: [any MTLTexture] = []
        var missing: [ClosedRange<Int>?] = []
        var shown: Int?
        var size = (width: 0, height: 0)
    }

    public nonisolated let cellMetrics: RenderMetrics
    private let recorder: CPURenderer
    private let compositor: MetalCompositor
    private var ring = Ring()
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
    var frameBufferCount: Int { ring.textures.count }

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
        if ring.size != size || ring.surfaces.isEmpty {
            guard makeRing(width: size.width, height: size.height) else {
                failed.withLock { $0 = true }
                return false
            }
            recorder.invalidate()
        }
        let frame = recorder.record(
            screen,
            width: size.width,
            height: size.height,
            cursorVisible: cursorVisible,
            textBlinkVisible: textBlinkVisible,
            view: view
        )
        guard let changed = frame.changedPixelRows else { return false }
        let target = ((ring.shown ?? Self.bufferCount - 1) + 1) % Self.bufferCount
        // Without a surface shown yet, the frame draws everything (the renderer was invalidated with the ring).
        let previous = ring.shown.map { ring.textures[$0] }
        let missing = ring.missing[target].map { Self.rows($0, without: frame.move) } ?? []
        do {
            try await compositor.apply(
                frame,
                to: ring.textures[target],
                restoring: previous.map { (missing, $0) },
                movingFrom: previous
            )
        } catch {
            // The frame was not drawn and the GPU may be gone: the window is told to use the CPU renderer.
            recorder.invalidate()
            failed.withLock { $0 = true }
            return false
        }
        ring.missing[target] = nil
        for other in 0 ..< Self.bufferCount where other != target {
            ring.missing[other] = merge(ring.missing[other], changed)
        }
        ring.shown = target
        let surface = ring.surfaces[target]
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

    private func merge(_ first: ClosedRange<Int>?, _ second: ClosedRange<Int>) -> ClosedRange<Int> {
        guard let first else { return second }
        return min(first.lowerBound, second.lowerBound) ... max(first.upperBound, second.upperBound)
    }

    private func makeRing(width: Int, height: Int) -> Bool {
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)
        var surfaces: [IOSurface] = []
        var textures: [any MTLTexture] = []
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .rgba8Unorm,
            width: width,
            height: height,
            mipmapped: false
        )
        descriptor.usage = [.renderTarget, .shaderRead]
        for _ in 0 ..< Self.bufferCount {
            guard
                let surface = IOSurface(properties: [
                    .width: width, .height: height, .bytesPerElement: 4, .pixelFormat: Self.pixelFormat
                ]), let texture = compositor.device.makeTexture(descriptor: descriptor, iosurface: surface, plane: 0)
            else { return false }
            if let colorSpace, let list = colorSpace.copyPropertyList() {
                surface.setAttachment(list, forKey: kIOSurfaceColorSpace as String)
            }
            surfaces.append(surface)
            textures.append(texture)
        }
        ring = Ring(
            surfaces: surfaces,
            textures: textures,
            // A new surface has none of the frame yet: all of it is missing.
            missing: [ClosedRange<Int>?](repeating: 0 ... height - 1, count: Self.bufferCount),
            shown: nil,
            size: (width, height)
        )
        return true
    }
}
