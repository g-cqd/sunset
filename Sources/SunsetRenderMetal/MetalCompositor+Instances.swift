internal import Metal
internal import SunsetRender

/// The frame's instances, written straight into the mapped buffer: copy quads first, then the operations with their glyphs placed in the atlas.
extension MetalCompositor {
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

    /// Writes the frame's instances into the instance buffer; how many. A frame whose glyphs do not fit in what is left of the atlas is written again after
    /// clearing it.
    func writeInstances(for frame: DrawFrame, copies: [Instance]) throws -> Int {
        let count = copies.count + frame.ops.count
        guard count > 0 else { return 0 }
        if slotsGeneration != frame.glyphGeneration {
            clearAtlas()
            slotsGeneration = frame.glyphGeneration
        }
        guard let buffer = buffer(forInstances: count) else { throw Failure.commandFailed }
        let base = unsafe buffer.contents().bindMemory(to: Instance.self, capacity: count)
        for (index, copy) in copies.enumerated() { unsafe (base + index).initialize(to: copy) }
        for attempt in 0 ..< 2 {
            if unsafe write(frame, into: base + copies.count) { return count }
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

    /// The copy quads that come before the frame's operations: the rows restored, then the move (each full width, read from the picture before).
    static func copies(restoring rows: [ClosedRange<Int>], move: PixelMove?, width: Int) -> [Instance] {
        func copy(to destinationY: Int, from sourceY: Int, height: Int) -> Instance {
            Instance(
                x: 0,
                y: Int32(destinationY),
                width: Int32(width),
                height: Int32(height),
                color: 0,
                glyph: copyMark,
                sourceX: 0,
                sourceY: Int32(sourceY)
            )
        }
        var list = rows.map { copy(to: $0.lowerBound, from: $0.lowerBound, height: $0.count) }
        if let move, move.height > 0 {
            list.append(copy(to: move.destinationY, from: move.sourceY, height: move.height))
        }
        return list
    }

    /// `Instance.glyph` of a copy quad (the shader's `0xFFFFFFFF`).
    private static let copyMark = UInt32.max

    private func buffer(forInstances count: Int) -> (any MTLBuffer)? {
        let needed = count * MemoryLayout<Instance>.stride
        if let instances, instances.length >= needed { return instances }
        // Grown in steps, so that a frame a little bigger than the last does not allocate again.
        instances = device.makeBuffer(length: max(needed * 2, 64 * 1024), options: .storageModeShared)
        return instances
    }
}
