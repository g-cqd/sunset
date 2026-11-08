import Metal
import SunsetCore
import SunsetRender
import SunsetRenderMac
import Testing

@testable import SunsetRenderMetal

/// The CPU renderer (the oracle) and the Metal renderer fed the same screens, to compare their pixels.
struct MetalRig {
    var terminal: Terminal
    let metrics: RenderMetrics
    let cpu: CPURenderer
    let gpuSide: CPURenderer
    let metal: MetalCompositor
    var cpuSurface: Surface
    let target: any MTLTexture
    /// What `target` held after the frame before: where a scroll's pixels are moved from.
    let previous: any MTLTexture
    var alpha: UInt8 = 255
    /// The pixel move of the last frame, if it had one.
    var lastMove: PixelMove?

    static var device: (any MTLDevice)? { MTLCreateSystemDefaultDevice() }

    init?(columns: Int = 24, rows: Int = 6, font: String? = nil, ligatures: Bool = false) {
        guard let compositor = MetalCompositor() else { return nil }
        let glyphs: any GlyphSource
        var metrics: RenderMetrics
        if let font {
            let source = CoreTextGlyphSource(fontName: font, size: 28, features: [])
            glyphs = source
            metrics = source.metrics
        } else {
            metrics = RenderMetrics(cellWidth: 14, cellHeight: 28)
            glyphs = BoxGlyphSource()
        }
        metrics.paddingX = 3
        metrics.paddingY = 2
        self.metrics = metrics
        terminal = Terminal(columns: columns, rows: rows)
        cpu = CPURenderer(metrics: metrics, glyphs: glyphs, ligatures: ligatures)
        gpuSide = CPURenderer(metrics: metrics, glyphs: glyphs, ligatures: ligatures)
        metal = compositor
        let size = metrics.surfaceSize(columns: columns, rows: rows)
        cpuSurface = Surface(width: size.width, height: size.height)
        guard let texture = compositor.makeTarget(width: size.width, height: size.height),
            let shown = compositor.makeTarget(width: size.width, height: size.height)
        else { return nil }
        target = texture
        previous = shown
    }

    /// Draws a frame with both renderers.
    mutating func frame(_ text: String = "", cursorVisible: Bool = true, view: FrameView = FrameView()) async throws {
        terminal.feed(text)
        var view = view
        view.backgroundAlpha = alpha
        cpu.render(terminal.screen, into: &cpuSurface, cursorVisible: cursorVisible, view: view)
        let list = gpuSide.record(
            terminal.screen,
            width: cpuSurface.width,
            height: cpuSurface.height,
            cursorVisible: cursorVisible,
            view: view
        )
        lastMove = list.move
        // As the app does: the frame's rows are copied to a second texture, which the next frame's pixel move reads.
        try await metal.apply(list, to: target, copying: (0 ... target.height - 1, previous), movingFrom: previous)
        terminal.clearDirty()
    }

    /// The pixels the Metal renderer holds.
    func gpuSurface() -> Surface { metal.readback(target) }

    /// How many pixels differ and by how much at most.
    func differences() -> (count: Int, largest: Int) {
        let gpu = gpuSurface().pixels
        var count = 0
        var largest = 0
        for (a, b) in zip(cpuSurface.pixels, gpu) where a != b {
            count += 1
            for shift in stride(from: 0, to: 32, by: 8) {
                largest = max(largest, abs(Int((a >> UInt32(shift)) & 255) - Int((b >> UInt32(shift)) & 255)))
            }
        }
        return (count, largest)
    }
}
