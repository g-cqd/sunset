internal import Metal
internal import SunsetRender

/// The copies a frame makes besides drawing: the pixel move of a scroll (before drawing) and the changed rows to the shown surface (after).
extension MetalCompositor {
    /// Copies the rows of `move` from `source` into `target`, moved: `source` holds the picture of the frame before, so the regions never overlap in one texture.
    static func encode(
        _ move: PixelMove,
        from source: any MTLTexture,
        to target: any MTLTexture,
        into commands: any MTLCommandBuffer
    ) {
        guard move.height > 0, let blit = commands.makeBlitCommandEncoder() else { return }
        blit.copy(
            from: source,
            sourceSlice: 0,
            sourceLevel: 0,
            sourceOrigin: MTLOrigin(x: 0, y: move.sourceY, z: 0),
            sourceSize: MTLSize(width: target.width, height: move.height, depth: 1),
            to: target,
            destinationSlice: 0,
            destinationLevel: 0,
            destinationOrigin: MTLOrigin(x: 0, y: move.destinationY, z: 0)
        )
        blit.endEncoding()
    }

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
