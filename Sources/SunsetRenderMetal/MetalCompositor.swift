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
    }

    /// One operation as the shader reads it.
    private struct Instance {
        var x: Int32, y: Int32, width: Int32, height: Int32
        var color: UInt32
        var kind: UInt32
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
    private var atlas: GlyphAtlas
    private var instances: (any MTLBuffer)?
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

    /// Draws the frame's operations into `target`; returns when the GPU has finished (suspended meanwhile: no thread waits).
    public nonisolated(nonsending) func apply(_ frame: DrawFrame, to target: any MTLTexture) async throws {
        try await apply(frame, to: target, copying: nil)
    }

    /// Draws the frame into `target` and, in the same command buffer, copies the pixel rows `copy.rows` of it into `copy.destination` (the surface a window
    /// shows): the GPU moves the changed rows, nothing goes through the CPU.
    public nonisolated(nonsending) func apply(
        _ frame: DrawFrame,
        to target: any MTLTexture,
        copying copy: (rows: ClosedRange<Int>, destination: any MTLTexture)?
    ) async throws {
        guard !frame.ops.isEmpty || copy != nil else { return }
        // The atlas and the instance buffer are written for this frame: the frame before must be finished, which a second caller would break.
        precondition(!drawing, "MetalCompositor.apply is one frame at a time")
        drawing = true
        defer { drawing = false }
        let list = try instanceList(for: frame)
        guard let commands = queue.makeCommandBuffer() else { throw Failure.commandFailed }
        if !list.isEmpty { try encodeDraw(list, frame: frame, target: target, into: commands) }
        if let copy, let blit = commands.makeBlitCommandEncoder() {
            let rows = max(copy.rows.lowerBound, 0) ... min(copy.rows.upperBound, target.height - 1)
            blit.copy(
                from: target,
                sourceSlice: 0,
                sourceLevel: 0,
                sourceOrigin: MTLOrigin(x: 0, y: rows.lowerBound, z: 0),
                sourceSize: MTLSize(width: target.width, height: rows.count, depth: 1),
                to: copy.destination,
                destinationSlice: 0,
                destinationLevel: 0,
                destinationOrigin: MTLOrigin(x: 0, y: rows.lowerBound, z: 0)
            )
            blit.endEncoding()
        }
        let finished = await Self.run(commands)
        lastGPUSeconds = commands.gpuEndTime - commands.gpuStartTime
        lastInstanceCount = list.count
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

    private func encodeDraw(
        _ list: [Instance],
        frame: DrawFrame,
        target: any MTLTexture,
        into commands: any MTLCommandBuffer
    ) throws {
        guard let buffer = buffer(forInstances: list.count) else { throw Failure.commandFailed }
        list.withUnsafeBytes { bytes in
            if let base = bytes.baseAddress { unsafe buffer.contents().copyMemory(from: base, byteCount: bytes.count) }
        }
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
        encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4, instanceCount: list.count)
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

    // MARK: Instances

    private func instanceList(for frame: DrawFrame) throws -> [Instance] {
        for attempt in 0 ..< 2 {
            if let list = makeInstances(frame) { return list }
            guard attempt == 0 else { break }
            atlas.clear()
        }
        throw Failure.atlasFull
    }

    private func makeInstances(_ frame: DrawFrame) -> [Instance]? {
        var list: [Instance] = []
        list.reserveCapacity(frame.ops.count)
        for op in frame.ops {
            switch op {
                case .fill(let x, let y, let width, let height, let color):
                    list.append(
                        Instance(
                            x: Int32(x),
                            y: Int32(y),
                            width: Int32(width),
                            height: Int32(height),
                            color: color,
                            kind: 0,
                            sourceX: 0,
                            sourceY: 0
                        )
                    )
                case .glyph(let bitmap, let sourceX, let sourceY, let width, let height, let x, let y, let color):
                    guard let slot = atlas.slot(for: bitmap) else { return nil }
                    list.append(
                        Instance(
                            x: Int32(x),
                            y: Int32(y),
                            width: Int32(width),
                            height: Int32(height),
                            color: color,
                            kind: 1,
                            sourceX: Int32(slot.x + sourceX),
                            sourceY: Int32(slot.y + sourceY)
                        )
                    )
            }
        }
        return list
    }

    private func buffer(forInstances count: Int) -> (any MTLBuffer)? {
        let needed = count * MemoryLayout<Instance>.stride
        if let instances, instances.length >= needed { return instances }
        // Grown in steps, so that a frame a little bigger than the last does not allocate again.
        instances = device.makeBuffer(length: max(needed * 2, 64 * 1024), options: .storageModeShared)
        return instances
    }
}
