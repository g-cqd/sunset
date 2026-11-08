internal import Metal
internal import SunsetRender

/// The blit a frame can make besides drawing: the changed rows copied to another texture after drawing (for tests and probes).
extension MetalCompositor {
    /// Copies the pixel rows `rows` of `target` into `destination`, in place.
    static func encodeCopy(
        rows wanted: ClosedRange<Int>,
        of target: any MTLTexture,
        to destination: any MTLTexture,
        into commands: any MTLCommandBuffer
    ) {
        let rows = max(wanted.lowerBound, 0) ... min(wanted.upperBound, target.height - 1)
        guard !rows.isEmpty, let blit = commands.makeBlitCommandEncoder() else { return }
        blit.copy(
            from: target,
            sourceSlice: 0,
            sourceLevel: 0,
            sourceOrigin: MTLOrigin(x: 0, y: rows.lowerBound, z: 0),
            sourceSize: MTLSize(width: target.width, height: rows.count, depth: 1),
            to: destination,
            destinationSlice: 0,
            destinationLevel: 0,
            destinationOrigin: MTLOrigin(x: 0, y: rows.lowerBound, z: 0)
        )
        blit.endEncoding()
    }
}
