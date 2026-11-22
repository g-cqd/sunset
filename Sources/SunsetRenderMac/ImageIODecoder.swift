internal import CoreGraphics
internal import ImageIO
public import SunsetRender

/// Reads the PNG files programs send (ADR-0117) with ImageIO, the decoder macOS's own apps use: only a PNG (the type ImageIO
/// finds, not the one the program claims), whole, at most `RenderImage`'s pixel limit, drawn premultiplied into sRGB.
public struct ImageIODecoder: ImageDecoding {
    /// The most pixels a file is read with (64 MiB at four bytes a pixel), as the renderer allows.
    private static let pixelLimit = 1 << 24

    /// The last chunk of every PNG file: its length (0), its type, its checksum.
    private static let end: [UInt8] = [0, 0, 0, 0, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82]

    public init() {}

    public func decodePNG(_ file: [UInt8]) -> DecodedImage? {
        // A file cut short is not drawn in part (ImageIO would, as a browser does; kitty does not): it ends with its IEND chunk.
        guard file.count > Self.end.count, file.suffix(Self.end.count).elementsEqual(Self.end),
            let data = CFDataCreate(nil, file, file.count),
            let source = CGImageSourceCreateWithData(data, nil),
            CGImageSourceGetType(source) as String? == "public.png",
            CGImageSourceGetCount(source) > 0,
            let image = CGImageSourceCreateImageAtIndex(source, 0, nil),
            image.width > 0, image.height > 0, image.width * image.height <= Self.pixelLimit,
            let space = CGColorSpace(name: CGColorSpace.sRGB)
        else { return nil }
        let (width, height) = (image.width, image.height)
        var rgba = [UInt8](repeating: 0, count: width * height * 4)
        let drawn = rgba.withUnsafeMutableBytes { bytes -> Bool in
            guard
                let context = unsafe CGContext(
                    data: bytes.baseAddress,
                    width: width,
                    height: height,
                    bitsPerComponent: 8,
                    bytesPerRow: width * 4,
                    space: space,
                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
                )
            else { return false }
            context.setBlendMode(.copy)
            context.interpolationQuality = .none
            context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
            return true
        }
        return drawn ? DecodedImage(width: width, height: height, rgba: rgba) : nil
    }
}
