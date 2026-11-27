import Foundation
public import Metal
public import SunsetRender

/// Applies a frame's draw list to a texture on the GPU (the CPU walks the dirty rows and writes the operations, the GPU draws them in one instanced
/// draw): the replay of what the CPU renderer would have drawn. The target keeps the picture between frames; a frame only brings what changed.
///
/// It is meant to be owned by one actor, whose isolation its async methods run in: one frame at a time (the owner awaits `apply` before the next), so nothing
/// the GPU still reads (the atlas, the instance buffer) is written.
public final class MetalCompositor {
    public enum Failure: Error {
        /// The frame's glyphs do not fit in the atlas even when it is empty.
        case atlasFull
        case commandFailed
        /// The frame moves or restores pixels and no picture before was given to take them from.
        case noMoveSource
    }

    /// One operation as the shader reads it: the op, with its source moved to where its glyph is in the atlas.
    struct Instance {
        var x: Int32, y: Int32, width: Int32, height: Int32
        var color: UInt32
        var glyph: UInt32
        var sourceX: Int32, sourceY: Int32
    }

    private struct Uniforms {
        var width: Float
        var height: Float
        var translucent: UInt32
        var padding: UInt32 = 0
    }

    public let device: any MTLDevice
    private let queue: any MTLCommandQueue
    private let pipeline: any MTLRenderPipelineState
    var atlas: GlyphAtlas
    var instances: (any MTLBuffer)?
    /// Where each of the renderer's glyphs is in the atlas, by glyph number - 1 (x -1: not uploaded), for the glyph generation `slotsGeneration`.
    var slots: ContiguousArray<SIMD2<Int32>> = []
    var slotsGeneration: UInt32?
    /// The frame's images uploaded, by number, for `imagesGeneration` (`MetalCompositor+Images`).
    var imageTextures: [UInt32: any MTLTexture] = [:]
    var imagesGeneration: UInt32?
    private var drawing = false
    /// What the GPU took for the last frame (start to end of its execution) and how many instances it drew: for probes.
    var lastGPUSeconds = 0.0
    var lastInstanceCount = 0

    /// Shared compiled Metal shader library & pipeline state per device (N-S9): avoids recompiling the MSL source on
    /// every new terminal pane/compositor creation.
    private static let sharedPipelineLock = NSLock()
    private nonisolated(unsafe) static var sharedPipelines: [ObjectIdentifier: any MTLRenderPipelineState] = [:]

    /// Held while compiling: a pane made while `prepare` compiles waits for it instead of compiling again.
    private static let compileLock = NSLock()

    private static func sharedPipeline(for device: any MTLDevice) -> (any MTLRenderPipelineState)? {
        compileLock.lock()
        defer { compileLock.unlock() }
        let key = ObjectIdentifier(device)
        sharedPipelineLock.lock()
        if let cached = sharedPipelines[key] {
            sharedPipelineLock.unlock()
            return cached
        }
        sharedPipelineLock.unlock()

        let options = MTLCompileOptions()
        options.mathMode = .safe
        guard let library = try? device.makeLibrary(source: MetalShaders.source, options: options),
            let vertex = library.makeFunction(name: "cell_vertex"),
            let fragment = library.makeFunction(name: "cell_fragment")
        else { return nil }
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = vertex
        descriptor.fragmentFunction = fragment
        descriptor.colorAttachments[0].pixelFormat = .rgba8Unorm
        guard let built = try? device.makeRenderPipelineState(descriptor: descriptor) else { return nil }

        sharedPipelineLock.lock()
        sharedPipelines[key] = built
        sharedPipelineLock.unlock()
        return built
    }

    /// One command queue per device, for every compositor (audit PERF-01/MEM-02: one a pane before).
    private nonisolated(unsafe) static var sharedQueues: [ObjectIdentifier: any MTLCommandQueue] = [:]

    private static func sharedQueue(for device: any MTLDevice) -> (any MTLCommandQueue)? {
        sharedPipelineLock.lock()
        defer { sharedPipelineLock.unlock() }
        if let queue = sharedQueues[ObjectIdentifier(device)] { return queue }
        guard let queue = device.makeCommandQueue() else { return nil }
        sharedQueues[ObjectIdentifier(device)] = queue
        return queue
    }

    /// Compiles the shaders for the default device now, off the main thread, so that the first terminal does not wait the
    /// ~150 ms of compiling them (audit PERF-01). Called once as the app starts.
    public static func prepare() {
        Thread.detachNewThread {
            guard let device = MTLCreateSystemDefaultDevice() else { return }
            _ = sharedPipeline(for: device)
            _ = sharedQueue(for: device)
        }
    }

    /// nil when there is no Metal device, or its shaders do not compile.
    public init?(device: (any MTLDevice)? = MTLCreateSystemDefaultDevice()) {
        guard let device, let queue = Self.sharedQueue(for: device), let atlas = GlyphAtlas(device: device),
            let pipeline = Self.sharedPipeline(for: device)
        else { return nil }
        self.device = device
        self.queue = queue
        self.pipeline = pipeline
        self.atlas = atlas
    }

    /// A texture a frame can be drawn into and read back from: red, green, blue, alpha bytes like a `Surface`.
    public func makeTarget(width: Int, height: Int) -> (any MTLTexture)? {
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .rgba8Unorm,
            width: width,
            height: height,
            mipmapped: false
        )
        descriptor.storageMode = .shared
        descriptor.usage = [.renderTarget, .shaderRead]
        return device.makeTexture(descriptor: descriptor)
    }

    /// Draws the frame's operations into `target`; returns when the GPU has finished (suspended meanwhile: no thread waits). A frame that moves pixels needs
    /// the longer form, with a texture to move them from.
    public nonisolated(nonsending) func apply(_ frame: DrawFrame, to target: any MTLTexture) async throws {
        try await apply(frame, to: target, previous: nil)
    }

    /// Draws the frame into `target`, all on the GPU, in one render pass:
    /// - the rows `restoring` of `previous` are copied first (a surface of a ring brought up to the one shown last);
    /// - then the frame's pixel move (a scroll, `DrawFrame.move`), also from `previous`, which must hold the picture of the frame before (the surface last
    ///   shown): rows cannot be moved within `target` itself while it is drawn into;
    /// - then the frame's operations.
    /// The copies are quads that read `previous`, not blit commands: the first blit after a pause makes the Metal driver take ~45 MB more of the process's
    /// footprint for a second or two, on top of the ~50 MB a render pass takes (measured; any size of texture). `copy` (rows of `target` into
    /// `copy.destination`, after drawing) is a blit, for tests and probes.
    public nonisolated(nonsending) func apply(
        _ frame: DrawFrame,
        to target: any MTLTexture,
        previous: (any MTLTexture)? = nil,
        restoring restore: [ClosedRange<Int>] = [],
        copying copy: (rows: ClosedRange<Int>, destination: any MTLTexture)? = nil
    ) async throws {
        guard !frame.ops.isEmpty || copy != nil || frame.move != nil || !restore.isEmpty else { return }
        if frame.move != nil || !restore.isEmpty, previous == nil { throw Failure.noMoveSource }
        // The atlas and the instance buffer are written for this frame: the frame before must be finished, which a second caller would break.
        precondition(!drawing, "MetalCompositor.apply is one frame at a time")
        drawing = true
        defer { drawing = false }
        let count = try writeInstances(
            for: frame,
            copies: Self.copies(restoring: restore, move: frame.move, width: target.width)
        )
        try uploadImages(of: frame)
        guard let commands = queue.makeCommandBuffer() else { throw Failure.commandFailed }
        if count > 0 { try encodeDraw(count, frame: frame, target: target, previous: previous, into: commands) }
        if let copy { Self.encodeCopy(rows: copy.rows, of: target, to: copy.destination, into: commands) }
        let finished = await Self.run(commands)
        lastGPUSeconds = commands.gpuEndTime - commands.gpuStartTime
        lastInstanceCount = count
        guard finished else { throw Failure.commandFailed }
    }

    /// Commits `commands` and suspends until the GPU has run them; whether they completed without error.
    private nonisolated(nonsending) static func run(_ commands: any MTLCommandBuffer) async -> Bool {
        await withCheckedContinuation { (done: CheckedContinuation<Bool, Never>) in
            // Registered before `commit`, as Metal requires; called by Metal's own thread once the GPU is done.
            commands.addCompletedHandler { buffer in done.resume(returning: buffer.status == .completed) }
            commands.commit()
        }
    }

    /// Draws the first `count` instances of the instance buffer.
    private func encodeDraw(
        _ count: Int,
        frame: DrawFrame,
        target: any MTLTexture,
        previous: (any MTLTexture)?,
        into commands: any MTLCommandBuffer
    ) throws {
        guard let buffer = instances else { throw Failure.commandFailed }
        let pass = MTLRenderPassDescriptor()
        pass.colorAttachments[0].texture = target
        pass.colorAttachments[0].loadAction = .load
        pass.colorAttachments[0].storeAction = .store
        guard let encoder = commands.makeRenderCommandEncoder(descriptor: pass) else { throw Failure.commandFailed }
        var uniforms = Uniforms(
            width: Float(target.width),
            height: Float(target.height),
            translucent: frame.translucent ? 1 : 0
        )
        encoder.setRenderPipelineState(pipeline)
        encoder.setVertexBuffer(buffer, offset: 0, index: 0)
        encoder.setFragmentBuffer(buffer, offset: 0, index: 0)
        unsafe encoder.setVertexBytes(&uniforms, length: MemoryLayout<Uniforms>.size, index: 1)
        unsafe encoder.setFragmentBytes(&uniforms, length: MemoryLayout<Uniforms>.size, index: 1)
        encoder.setFragmentTexture(atlas.texture, index: 0)
        // Read only by copy quads, which a frame has only with a picture before; something is bound in any case.
        encoder.setFragmentTexture(previous ?? atlas.texture, index: 1)
        // Read only by image quads, which bind their own (`drawInstances`).
        encoder.setFragmentTexture(atlas.texture, index: 2)
        drawInstances(count, frame: frame, encoder: encoder)
        encoder.endEncoding()
    }

    /// The pixels of `texture`, as the CPU renderer's surface holds them.
    public func readback(_ texture: any MTLTexture) -> Surface {
        var pixels = ContiguousArray<UInt32>(repeating: 0, count: texture.width * texture.height)
        pixels.withUnsafeMutableBytes { bytes in
            if let base = bytes.baseAddress {
                unsafe texture.getBytes(
                    base,
                    bytesPerRow: texture.width * 4,
                    from: MTLRegionMake2D(0, 0, texture.width, texture.height),
                    mipmapLevel: 0
                )
            }
        }
        return Surface(width: texture.width, height: texture.height, pixels: pixels)
    }
}
