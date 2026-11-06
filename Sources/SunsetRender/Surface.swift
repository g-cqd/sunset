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
        var bytes: [UInt8] = []
        bytes.reserveCapacity(pixels.count * 4)
        for value in pixels {
            bytes.append(UInt8(truncatingIfNeeded: value))
            bytes.append(UInt8(truncatingIfNeeded: value >> 8))
            bytes.append(UInt8(truncatingIfNeeded: value >> 16))
            bytes.append(UInt8(truncatingIfNeeded: value >> 24))
        }
        return bytes
    }
}
