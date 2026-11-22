/// Draws an image's premultiplied pixels over a surface's: the one kernel of the CPU renderer and of `DrawFrame.replay`, and the
/// formula the Metal shader computes, so that the three agree bit for bit. Per channel `(p * 255 + d * (255 - a) + 127) / 255`
/// with `a` the image pixel's alpha; the alpha likewise when the surface is translucent, else 255.
enum ImageBlend {
    /// `size` of `image` from `source`, at `place` in `surface`. The rectangle is inside both.
    static func draw(
        _ image: RenderImage,
        from source: (x: Int, y: Int),
        to place: (x: Int, y: Int),
        size: (width: Int, height: Int),
        into surface: inout Surface,
        translucent: Bool
    ) {
        image.pixels.withUnsafeBufferPointer { from in
            let stride = surface.width
            surface.pixels.withUnsafeMutableBufferPointer { into in
                guard let read = from.baseAddress, let write = into.baseAddress else { return }
                for row in 0 ..< size.height {
                    let start = unsafe read + (source.y + row) * image.width + source.x
                    let end = unsafe write + (place.y + row) * stride + place.x
                    unsafe blend(start, over: end, count: size.width, translucent: translucent)
                }
            }
        }
    }

    @inline(__always) private static func blend(
        _ source: UnsafePointer<UInt32>,
        over destination: UnsafeMutablePointer<UInt32>,
        count: Int,
        translucent: Bool
    ) {
        for index in 0 ..< count {
            let pixel = unsafe source[index]
            let alpha = pixel >> 24
            if alpha == 255 {
                unsafe destination[index] = pixel
                continue
            }
            if alpha == 0 { continue }
            let below = unsafe destination[index]
            let inverse = 255 - alpha
            func channel(_ shift: UInt32) -> UInt32 {
                ((pixel >> shift & 255) * 255 + (below >> shift & 255) * inverse + 127) / 255
            }
            let out = translucent ? (alpha * 255 + (below >> 24) * inverse + 127) / 255 : 255
            unsafe destination[index] = channel(0) | channel(8) << 8 | channel(16) << 16 | out << 24
        }
    }
}
