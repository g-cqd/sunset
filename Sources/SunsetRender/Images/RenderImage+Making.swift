internal import SunsetCore

/// An image the program sent, made into what the renderers draw: read (a PNG through the platform's decoder), premultiplied,
/// and scaled to the size it is shown at.
extension RenderImage {
    /// The most pixels an image is read or drawn with (64 MiB at four bytes a pixel): an image placed over many cells is not
    /// made a gigabyte.
    static let pixelLimit = 1 << 24

    /// `image` at `width` × `height`; nil when it does not read or is larger than `pixelLimit`.
    static func make(_ image: TerminalImage, width: Int, height: Int, decoder: (any ImageDecoding)?) -> RenderImage? {
        guard width > 0, height > 0, width * height <= pixelLimit, image.width * image.height <= pixelLimit,
            let source = read(image, decoder: decoder)
        else { return nil }
        if source.width == width, source.height == height { return source }
        return RenderImage(width: width, height: height, pixels: source.resampled(width: width, height: height))
    }

    /// The image at its own size, premultiplied.
    private static func read(_ image: TerminalImage, decoder: (any ImageDecoding)?) -> RenderImage? {
        let count = image.width * image.height
        var pixels = ContiguousArray<UInt32>(repeating: 0, count: count)
        switch image.format {
            case .rgb:
                guard image.pixels.count >= count * 3 else { return nil }
                for index in 0 ..< count {
                    let byte = index * 3
                    pixels[index] =
                        UInt32(image.pixels[byte]) | UInt32(image.pixels[byte + 1]) << 8
                        | UInt32(image.pixels[byte + 2]) << 16 | 0xFF00_0000
                }
            case .rgba:
                guard image.pixels.count >= count * 4 else { return nil }
                for index in 0 ..< count { pixels[index] = premultiplied(image.pixels, at: index * 4) }
            case .png:
                guard let decoded = decoder?.decodePNG(image.pixels), decoded.width * decoded.height <= pixelLimit
                else {
                    return nil
                }
                pixels = ContiguousArray(repeating: 0, count: decoded.width * decoded.height)
                for index in 0 ..< pixels.count { pixels[index] = packed(decoded.rgba, at: index * 4) }
                return RenderImage(width: decoded.width, height: decoded.height, pixels: pixels)
        }
        return RenderImage(width: image.width, height: image.height, pixels: pixels)
    }

    /// Straight RGBA at `byte`, premultiplied and packed: each colour times the alpha, rounded, as `Surface.pack(_:alpha:)`.
    private static func premultiplied(_ bytes: [UInt8], at byte: Int) -> UInt32 {
        let alpha = UInt32(bytes[byte + 3])
        func scale(_ channel: UInt8) -> UInt32 {
            (UInt32(channel) * alpha + 127) / 255
        }
        return scale(bytes[byte]) | scale(bytes[byte + 1]) << 8 | scale(bytes[byte + 2]) << 16 | alpha << 24
    }

    private static func packed(_ bytes: [UInt8], at byte: Int) -> UInt32 {
        UInt32(bytes[byte]) | UInt32(bytes[byte + 1]) << 8 | UInt32(bytes[byte + 2]) << 16 | UInt32(bytes[byte + 3])
            << 24
    }

    /// The image scaled to `width` × `height`: each pixel the four nearest of the image weighed by distance (bilinear), on
    /// the premultiplied values, so a colour stays at most its alpha.
    func resampled(width newWidth: Int, height newHeight: Int) -> ContiguousArray<UInt32> {
        var out = ContiguousArray<UInt32>(repeating: 0, count: newWidth * newHeight)
        let scaleX = Float(width) / Float(newWidth)
        let scaleY = Float(height) / Float(newHeight)
        for y in 0 ..< newHeight {
            let sourceY = min(max((Float(y) + 0.5) * scaleY - 0.5, 0), Float(height - 1))
            let (top, fractionY) = (Int(sourceY), sourceY - Float(Int(sourceY)))
            let bottom = min(top + 1, height - 1)
            for x in 0 ..< newWidth {
                let sourceX = min(max((Float(x) + 0.5) * scaleX - 0.5, 0), Float(width - 1))
                let (left, fractionX) = (Int(sourceX), sourceX - Float(Int(sourceX)))
                let right = min(left + 1, width - 1)
                let corners = (
                    pixels[top * width + left], pixels[top * width + right], pixels[bottom * width + left],
                    pixels[bottom * width + right]
                )
                var result: UInt32 = 0
                for shift in stride(from: UInt32(0), to: 32, by: 8) {
                    func channel(_ pixel: UInt32) -> Float {
                        Float(pixel >> shift & 255)
                    }
                    let upper = channel(corners.0) + (channel(corners.1) - channel(corners.0)) * fractionX
                    let lower = channel(corners.2) + (channel(corners.3) - channel(corners.2)) * fractionX
                    let value = (upper + (lower - upper) * fractionY).rounded()
                    result |= UInt32(min(max(value, 0), 255)) << shift
                }
                out[y * newWidth + x] = result
            }
        }
        return out
    }
}
