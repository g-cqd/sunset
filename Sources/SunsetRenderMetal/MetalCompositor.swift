public import Metal
public import SunsetRender

/// Applies a frame's draw list to a texture on the GPU (ADR-0021: the CPU walks the dirty rows and writes the operations, the GPU draws them in one
/// instanced draw): the replay of what the CPU renderer would have drawn. The target keeps the picture between frames; a frame only brings what changed.
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
    private var drawing = false
    /// What the GPU took for the last frame (start to end of its execution) and how many instances it drew: for probes.
    var lastGPUSeconds = 0.0
    var lastInstanceCount = 0

    /// nil when there is no Metal device, or its shaders do not compile.
    public init?(device: (any MTLDevice)? = MTLCreateSystemDefaultDevice()) {
        guard let device, let queue = device.makeCommandQueue(), let atlas = GlyphAtlas(device: device) else {
            return nil
        }
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
        guard let pipeline = try? device.makeRenderPipelineState(descriptor: descriptor) else { return nil }
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
        encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4, instanceCount: count)
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

    /// Glyphs the atlas holds (for tests and probes).
    var atlasGlyphs: Int { atlas.count }
}
