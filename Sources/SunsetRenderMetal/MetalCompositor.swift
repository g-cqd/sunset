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
        /// The frame moves pixels and no texture was given to move them from.
        case noMoveSource
    }

    /// One operation as the shader reads it: the op, with its source moved to where its glyph is in the atlas.
    private struct Instance {
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
    private var atlas: GlyphAtlas
    private var instances: (any MTLBuffer)?
    /// Where each of the renderer's glyphs is in the atlas, by glyph number - 1 (x -1: not uploaded), for the glyph generation `slotsGeneration`.
    private var slots: ContiguousArray<SIMD2<Int32>> = []
    private var slotsGeneration: UInt32?
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
        try await apply(frame, to: target, copying: nil, movingFrom: nil)
    }

    /// Draws the frame into `target`, all in one command buffer, in this order:
    /// - `restore`: copies the rows `restore.rows` of `restore.source` into `target` first (a surface of a ring brought up to the one shown last);
    /// - the frame's pixel move (a scroll, `DrawFrame.move`), copied from `previous`, which must hold the picture of the frame before (the surface last shown):
    ///   Metal leaves a copy between overlapping regions of one texture undefined, so the rows cannot be moved within `target` itself;
    /// - the frame's operations;
    /// - `copy`: the pixel rows `copy.rows` of `target` copied into `copy.destination`.
    /// Nothing goes through the CPU.
    public nonisolated(nonsending) func apply(
        _ frame: DrawFrame,
        to target: any MTLTexture,
        restoring restore: (rows: [ClosedRange<Int>], source: any MTLTexture)? = nil,
        copying copy: (rows: ClosedRange<Int>, destination: any MTLTexture)? = nil,
        movingFrom previous: (any MTLTexture)? = nil
    ) async throws {
        let restores = restore.map { !$0.rows.isEmpty } ?? false
        guard !frame.ops.isEmpty || copy != nil || frame.move != nil || restores else { return }
        // The atlas and the instance buffer are written for this frame: the frame before must be finished, which a second caller would break.
        precondition(!drawing, "MetalCompositor.apply is one frame at a time")
        drawing = true
        defer { drawing = false }
        let count = try writeInstances(for: frame)
        guard let commands = queue.makeCommandBuffer() else { throw Failure.commandFailed }
        for rows in restore?.rows ?? [] {
            if let source = restore?.source { Self.encodeCopy(rows: rows, of: source, to: target, into: commands) }
        }
        if let move = frame.move {
            guard let previous else { throw Failure.noMoveSource }
            Self.encode(move, from: previous, to: target, into: commands)
        }
        if count > 0 { try encodeDraw(count, frame: frame, target: target, into: commands) }
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

    /// Where glyph number `glyph` of the frame is in the atlas, uploading it the first time; nil when the atlas is full.
    private func slot(of glyph: UInt32, in frame: DrawFrame) -> SIMD2<Int32>? {
        let index = Int(glyph) - 1
        if slots.count < frame.glyphs.count {
            slots.append(contentsOf: repeatElement(SIMD2(-1, -1), count: frame.glyphs.count - slots.count))
        }
        if slots[index].x >= 0 { return slots[index] }
        guard let place = atlas.place(frame.glyphs[index]) else { return nil }
        slots[index] = SIMD2(place.x, place.y)
        return slots[index]
    }

    /// Forgets every upload: the atlas and the slots start again.
    private func clearAtlas() {
        atlas.clear()
        slots.removeAll(keepingCapacity: true)
    }

    // MARK: Instances

    /// Writes the frame's instances into the instance buffer; how many. A frame whose glyphs do not fit in what is left of the atlas is written again after
    /// clearing it.
    private func writeInstances(for frame: DrawFrame) throws -> Int {
        guard !frame.ops.isEmpty else { return 0 }
        if slotsGeneration != frame.glyphGeneration {
            clearAtlas()
            slotsGeneration = frame.glyphGeneration
        }
        guard let buffer = buffer(forInstances: frame.ops.count) else { throw Failure.commandFailed }
        let base = unsafe buffer.contents().bindMemory(to: Instance.self, capacity: frame.ops.count)
        for attempt in 0 ..< 2 {
            if unsafe write(frame, into: base) { return frame.ops.count }
            guard attempt == 0 else { break }
            clearAtlas()
        }
        throw Failure.atlasFull
    }

    /// Whether every glyph of the frame found a place in the atlas.
    private func write(_ frame: DrawFrame, into base: UnsafeMutablePointer<Instance>) -> Bool {
        for (index, op) in frame.ops.enumerated() {
            var instance = Instance(
                x: op.x,
                y: op.y,
                width: op.width,
                height: op.height,
                color: op.color,
                glyph: op.glyph,
                sourceX: op.sourceX,
                sourceY: op.sourceY
            )
            if op.glyph != 0 {
                guard let slot = slot(of: op.glyph, in: frame) else { return false }
                instance.sourceX &+= slot.x
                instance.sourceY &+= slot.y
            }
            unsafe (base + index).initialize(to: instance)
        }
        return true
    }

    private func buffer(forInstances count: Int) -> (any MTLBuffer)? {
        let needed = count * MemoryLayout<Instance>.stride
        if let instances, instances.length >= needed { return instances }
        // Grown in steps, so that a frame a little bigger than the last does not allocate again.
        instances = device.makeBuffer(length: max(needed * 2, 64 * 1024), options: .storageModeShared)
        return instances
    }
}
