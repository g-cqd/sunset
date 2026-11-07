public import SunsetCore

/// A pixel buffer the renderer draws into: 8 bits per channel, bytes in the order red, green, blue, alpha (a pixel is read as one little-endian `UInt32`).
/// Opaque: the renderer writes alpha 255.
public struct Surface: Sendable {
    public let width: Int
    public let height: Int
    public internal(set) var pixels: ContiguousArray<UInt32>

    public init(width: Int, height: Int) {
        precondition(width > 0 && height > 0, "a surface has at least one pixel")
        self.width = width
        self.height = height
        pixels = ContiguousArray(repeating: 0xFF00_0000, count: width * height)
    }

    @inline(__always) static func pack(_ color: RGB) -> UInt32 {
        UInt32(color.red) | UInt32(color.green) << 8 | UInt32(color.blue) << 16 | 0xFF00_0000
    }

    /// A colour at `alpha` (0 to 255) as a premultiplied pixel: each channel times the alpha, rounded.
    @inline(__always) static func pack(_ color: RGB, alpha: UInt8) -> UInt32 {
        if alpha == 255 { return pack(color) }
        func scale(_ channel: UInt8) -> UInt32 { (UInt32(channel) * UInt32(alpha) + 127) / 255 }
        return UInt32(alpha) << 24 | scale(color.blue) << 16 | scale(color.green) << 8 | scale(color.red)
    }

    public subscript(x: Int, y: Int) -> RGB {
        let value = pixels[y * width + x]
        return RGB(
            UInt8(truncatingIfNeeded: value),
            UInt8(truncatingIfNeeded: value >> 8),
            UInt8(truncatingIfNeeded: value >> 16)
        )
    }

    /// The pixels as bytes, red first: what an image file or a texture upload wants.
    public var rgbaBytes: [UInt8] {
        // A pixel is one little-endian `UInt32` (red in the lowest byte), so the memory already is red, green, blue, alpha: one bulk copy.
        pixels.withUnsafeBytes { [UInt8]($0) }
    }
}
