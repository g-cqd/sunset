internal import CoreGraphics
public import IOSurface
internal import Metal
public import SunsetCore
public import SunsetRender
public import SunsetRenderMac
internal import Synchronization

/// The Metal renderer behind `IOSurfaceRenderer`: the CPU renderer works out the frame's operations (`CPURenderer.record`), `MetalCompositor` draws them into a
/// canvas texture that keeps the picture, and the rows that changed are copied on the GPU into one of three `IOSurface`s the layer shows (the one just shown is
/// never written: the compositor may still be reading it). Each surface remembers the rows it missed, as `IOSurfacePresenter` does.
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
        var canvas: (any MTLTexture)?
    }

    public nonisolated let cellMetrics: RenderMetrics
    private let recorder: CPURenderer
    private let compositor: MetalCompositor
    private var ring = Ring()
    private nonisolated let shown = Mutex<IOSurface?>(nil)
    private nonisolated let failed = Mutex(false)

    /// nil when there is no Metal device.
    public init?(metrics: RenderMetrics, glyphs: any GlyphSource, ligatures: Bool) {
        guard let compositor = MetalCompositor() else { return nil }
        self.compositor = compositor
        cellMetrics = metrics
        recorder = CPURenderer(metrics: metrics, glyphs: glyphs, ligatures: ligatures)
    }

    public nonisolated var latest: IOSurface? { shown.withLock { $0 } }
    public nonisolated var backend: RendererBackend { .gpu }
    public nonisolated var hasFailed: Bool { failed.withLock { $0 } }

    public func present(_ screen: Screen, cursorVisible: Bool, textBlinkVisible: Bool, view: FrameView) async -> Bool {
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
        guard let changed = frame.changedPixelRows, let canvas = ring.canvas else { return false }
        let target = ((ring.shown ?? Self.bufferCount - 1) + 1) % Self.bufferCount
        let rows = merge(ring.missing[target], changed)
        do {
            try compositor.apply(frame, to: canvas, copying: (rows, ring.textures[target]))
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
        guard let canvas = compositor.makeTarget(width: width, height: height) else { return false }
        ring = Ring(
            surfaces: surfaces,
            textures: textures,
            // A new surface has none of the frame yet: all of it is missing.
            missing: [ClosedRange<Int>?](repeating: 0 ... height - 1, count: Self.bufferCount),
            shown: nil,
            size: (width, height),
            canvas: canvas
        )
        return true
    }
}
