public import SunsetCore

/// A pixel buffer the renderer draws into: 8 bits per channel, bytes in the order red, green, blue, alpha (a pixel is read as one little-endian `UInt32`).
/// Opaque: the renderer writes alpha 255.
public struct Surface: Sendable {
    public let width: Int
    public let height: Int
    public internal(set) var pixels: ContiguousArray<UInt32>
    /// The surface has no pixels and takes down what would be drawn instead (`CPURenderer.record`): held here, not in the renderer, so that appending is a
    /// write to an `inout` value, without the dynamic exclusivity check a class's property costs.
    let records: Bool
    var recorded: ContiguousArray<DrawOp> = []
    var recordedMove: PixelMove?

    public init(width: Int, height: Int) {
        precondition(width > 0 && height > 0, "a surface has at least one pixel")
        self.width = width
        self.height = height
        pixels = ContiguousArray(repeating: 0xFF00_0000, count: width * height)
        records = false
    }

    /// A surface with these pixels (`width` x `height` of them, row by row): what a backend reads back from its own storage.
    public init(width: Int, height: Int, pixels: ContiguousArray<UInt32>) {
        precondition(
            width > 0 && height > 0 && pixels.count == width * height,
            "one pixel for each place of the surface"
        )
        self.width = width
        self.height = height
        self.pixels = pixels
        records = false
    }

    /// A surface that has a size and no pixels: for recording a frame (`CPURenderer.record`), where nothing is written.
    init(unbackedWidth width: Int, height: Int) {
        self.width = width
        self.height = height
        pixels = []
        records = true
    }

    /// Moves full-width rows of pixels (`PixelMove`); a recording surface takes the move down instead, and it must come before any operation.
    mutating func apply(_ move: PixelMove) {
        guard !records else {
            precondition(recorded.isEmpty && recordedMove == nil, "a frame moves its pixels once, first")
            recordedMove = move
            return
        }
        precondition(
            move.height >= 0 && min(move.sourceY, move.destinationY) >= 0
                && max(move.sourceY, move.destinationY) + move.height <= height,
            "a move stays inside the surface"
        )
        let width = width
        pixels.withUnsafeMutableBufferPointer { buffer in
            guard let base = buffer.baseAddress else { return }
            // The two regions may overlap, which `update(from:count:)` allows.
            unsafe (base + move.destinationY * width)
                .update(from: base + move.sourceY * width, count: move.height * width)
        }
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
