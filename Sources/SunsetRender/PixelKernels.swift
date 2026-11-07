internal import CSunsetKernels

/// The pixel loops of the renderer that run in C with vector instructions (NEON on Apple silicon), behind the same interface as a Swift loop. Each has a
/// scalar reference in the same library, and the tests compare the two bit for bit.
enum PixelKernels {
    /// Blends `color` (packed like a pixel) over `destination` with `coverage` as the alpha of each pixel, exactly `(c*a + d*(255-a) + 127) / 255` per channel;
    /// coverage 0 leaves a pixel alone. The destination must be opaque (the renderer's surface always is). Both buffers have `count` elements.
    static func blend(
        _ destination: UnsafeMutablePointer<UInt32>,
        coverage: UnsafePointer<UInt8>,
        count: Int,
        color: UInt32
    ) {
        unsafe sunset_blend_coverage(destination, coverage, count, color)
    }

    static func blendScalar(
        _ destination: UnsafeMutablePointer<UInt32>,
        coverage: UnsafePointer<UInt8>,
        count: Int,
        color: UInt32
    ) {
        unsafe sunset_blend_coverage_scalar(destination, coverage, count, color)
    }

    /// The blend over a premultiplied destination of any alpha (a translucent background): see the header.
    static func blendPremultiplied(
        _ destination: UnsafeMutablePointer<UInt32>,
        coverage: UnsafePointer<UInt8>,
        count: Int,
        color: UInt32
    ) {
        unsafe sunset_blend_coverage_premul(destination, coverage, count, color)
    }

    static func blendPremultipliedScalar(
        _ destination: UnsafeMutablePointer<UInt32>,
        coverage: UnsafePointer<UInt8>,
        count: Int,
        color: UInt32
    ) {
        unsafe sunset_blend_coverage_premul_scalar(destination, coverage, count, color)
    }
}
