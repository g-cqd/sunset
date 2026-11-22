import AppKit
import Metal
import QuartzCore

/// The sky in an extended-range Metal layer (`App/SunsetSky.metal`): 16-bit float, linear extended sRGB, so that the sun's
/// heart can be brighter than white on a display with headroom. Drawn at the display's rate while in a window. Built by
/// `swift build` alone (no app bundle) the shader is missing and the view stays clear.
final class SunsetSkyLayerView: NSView {
    var frameAt: (Double, CGSize) -> SunsetSkyFrame
    private let metal = CAMetalLayer()
    private let start = CACurrentMediaTime()
    private var queue: (any MTLCommandQueue)?
    private var pipeline: (any MTLRenderPipelineState)?
    private var link: CADisplayLink?
    private var windowObservers: [any NSObjectProtocol] = []

    /// Whether it draws now: only while its window can be seen (it is a full-window EDR pass at the display's rate; the
    /// outside audit's ENG-01 found it running behind other windows and in the Dock).
    var isAnimating: Bool {
        link.map { !$0.isPaused } ?? false
    }

    init(frameAt: @escaping (Double, CGSize) -> SunsetSkyFrame) {
        self.frameAt = frameAt
        super.init(frame: .zero)
        wantsLayer = true
        setUp()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    override func makeBackingLayer() -> CALayer {
        metal
    }

    override var isFlipped: Bool {
        true
    }

    private func setUp() {
        guard let device = MTLCreateSystemDefaultDevice(), let library = try? device.makeDefaultLibrary(bundle: .main),
            let vertex = library.makeFunction(name: "sky_vertex"),
            let fragment = library.makeFunction(name: "sky_fragment")
        else { return }
        let described = MTLRenderPipelineDescriptor()
        described.vertexFunction = vertex
        described.fragmentFunction = fragment
        described.colorAttachments[0].pixelFormat = .rgba16Float
        pipeline = try? device.makeRenderPipelineState(descriptor: described)
        queue = device.makeCommandQueue()
        metal.device = device
        metal.pixelFormat = .rgba16Float
        metal.colorspace = CGColorSpace(name: CGColorSpace.extendedLinearSRGB)
        metal.wantsExtendedDynamicRangeContent = true
        metal.isOpaque = false
        metal.framebufferOnly = true
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        link?.invalidate()
        link = nil
        windowObservers.forEach { NotificationCenter.default.removeObserver($0) }
        windowObservers = []
        guard let window else { return }
        let made = displayLink(target: self, selector: #selector(step))
        made.add(to: .main, forMode: .common)
        link = made
        for name in [
            NSWindow.didChangeOcclusionStateNotification, NSWindow.didMiniaturizeNotification,
            NSWindow.didDeminiaturizeNotification
        ] {
            windowObservers.append(
                NotificationCenter.default.addObserver(forName: name, object: window, queue: .main) { [weak self] _ in
                    MainActor.assumeIsolated { self?.followWindow() }
                }
            )
        }
        followWindow()
    }

    /// Draws while the window can be seen, pauses otherwise.
    private func followWindow() {
        guard let window else { return }
        link?.isPaused = !(window.occlusionState.contains(.visible) && !window.isMiniaturized)
    }

    override func layout() {
        super.layout()
        let scale = window?.backingScaleFactor ?? 2
        metal.contentsScale = scale
        metal.drawableSize = CGSize(width: bounds.width * scale, height: bounds.height * scale)
    }

    @objc private func step(_ link: CADisplayLink) {
        guard let pipeline, let queue, bounds.width > 0, let drawable = metal.nextDrawable(),
            let commands = queue.makeCommandBuffer()
        else { return }
        let pass = MTLRenderPassDescriptor()
        pass.colorAttachments[0].texture = drawable.texture
        pass.colorAttachments[0].loadAction = .clear
        pass.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        pass.colorAttachments[0].storeAction = .store
        guard let encoder = commands.makeRenderCommandEncoder(descriptor: pass) else { return }
        let time = CACurrentMediaTime() - start
        let headroom = window?.screen?.maximumExtendedDynamicRangeColorComponentValue ?? 1
        var uniforms = SunsetSkyUniforms(
            frameAt(time, bounds.size),
            time: time,
            headroom: headroom,
            scale: metal.contentsScale
        )
        encoder.setRenderPipelineState(pipeline)
        encoder.setFragmentBytes(&uniforms, length: MemoryLayout<SunsetSkyUniforms>.stride, index: 0)
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        encoder.endEncoding()
        commands.present(drawable)
        commands.commit()
    }
}
