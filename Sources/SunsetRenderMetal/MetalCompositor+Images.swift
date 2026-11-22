internal import Metal
internal import SunsetRender

/// Images (ADR-0117): each of the frame's uploaded once as a texture of its own, kept by number while the frame's image
/// generation stays the same; a frame with images is drawn in pieces, one for each change of the image bound.
extension MetalCompositor {
    /// Uploads the images the frame's operations draw that are not yet; forgets every upload when the generation changed.
    func uploadImages(of frame: DrawFrame) throws {
        guard !frame.images.isEmpty else { return }
        if imagesGeneration != frame.imageGeneration {
            imageTextures.removeAll()
            imagesGeneration = frame.imageGeneration
        }
        for op in frame.ops {
            guard let number = op.image, imageTextures[number] == nil else { continue }
            guard let texture = Self.texture(of: frame.images[Int(number)], on: device) else {
                throw Failure.commandFailed
            }
            imageTextures[number] = texture
        }
    }

    private static func texture(of image: RenderImage, on device: any MTLDevice) -> (any MTLTexture)? {
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .rgba8Unorm,
            width: image.width,
            height: image.height,
            mipmapped: false
        )
        descriptor.storageMode = .shared
        descriptor.usage = [.shaderRead]
        guard let texture = device.makeTexture(descriptor: descriptor) else { return nil }
        // Surface pixels hold red in the lowest byte: in memory, the bytes of `rgba8Unorm`.
        image.pixels.withUnsafeBytes { bytes in
            guard let base = bytes.baseAddress else { return }
            unsafe texture.replace(
                region: MTLRegionMake2D(0, 0, image.width, image.height),
                mipmapLevel: 0,
                withBytes: base,
                bytesPerRow: image.width * 4
            )
        }
        return texture
    }

    /// Draws the `count` instances (the copy quads, then the frame's operations, in order): in one call without images,
    /// else in one for each run that reads the same image.
    func drawInstances(_ count: Int, frame: DrawFrame, encoder: any MTLRenderCommandEncoder) {
        func draw(_ range: Range<Int>) {
            guard !range.isEmpty else { return }
            encoder.drawPrimitives(
                type: .triangleStrip,
                vertexStart: 0,
                vertexCount: 4,
                instanceCount: range.count,
                baseInstance: range.lowerBound
            )
        }
        guard !frame.images.isEmpty else { return draw(0 ..< count) }
        var start = 0
        var index = count - frame.ops.count
        var bound: UInt32?
        for op in frame.ops {
            if let number = op.image, number != bound, let texture = imageTextures[number] {
                draw(start ..< index)
                encoder.setFragmentTexture(texture, index: 2)
                (bound, start) = (number, index)
            }
            index += 1
        }
        draw(start ..< count)
    }
}
