/// Pixel blitting and Porter-Duff alpha composition helpers for Kitty animation frames (`a=f`, `a=c`).
enum ImageFrameBlit {
    struct Source {
        let bytes: [UInt8]
        let channels: Int
        let stride: Int
        let x: Int
        let y: Int
        let width: Int
        let height: Int
    }

    struct Target {
        let width: Int
        let height: Int
        let x: Int
        let y: Int
        let alphaBlend: Bool
    }

    static func rgbaPixels(of root: TerminalImage, anim: ImageAnimation, frame: Int) -> [UInt8] {
        if frame >= 2, let extra = anim.frames.first(where: { $0.index == frame }) {
            return extra.rgba
        }
        let count = root.width * root.height
        switch root.format {
            case .rgba:
                return root.pixels.count >= count * 4
                    ? Array(root.pixels.prefix(count * 4))
                    : [UInt8](repeating: 0, count: count * 4)
            case .rgb:
                var out = [UInt8](repeating: 255, count: count * 4)
                let limit = min(count, root.pixels.count / 3)
                for idx in 0 ..< limit {
                    out[idx * 4] = root.pixels[idx * 3]
                    out[idx * 4 + 1] = root.pixels[idx * 3 + 1]
                    out[idx * 4 + 2] = root.pixels[idx * 3 + 2]
                }
                return out
            case .png:
                return [UInt8](repeating: 0, count: count * 4)
        }
    }

    /// A canvas of the root's size filled with `background`, a 32-bit RGBA value as kitty's `Y` key gives it.
    static func filledCanvas(width: Int, height: Int, background: Int) -> [UInt8] {
        var out = [UInt8](repeating: 0, count: width * height * 4)
        let bg = UInt32(truncatingIfNeeded: background)
        guard bg != 0 else { return out }
        let rgba = [UInt8(bg >> 24 & 0xFF), UInt8(bg >> 16 & 0xFF), UInt8(bg >> 8 & 0xFF), UInt8(bg & 0xFF)]
        for offset in stride(from: 0, to: out.count, by: 4) {
            out.replaceSubrange(offset ..< offset + 4, with: rgba)
        }
        return out
    }

    /// Blits a rectangle from `source` (`channels` = 3 or 4) into RGBA `dst`.
    static func blit(_ source: Source, into dst: inout [UInt8], target: Target) {
        let copyW = min(source.width, max(source.stride - source.x, 0), max(target.width - target.x, 0))
        let copyH = min(source.height, max(target.height - target.y, 0))
        guard copyW > 0, copyH > 0 else { return }
        for y in 0 ..< copyH {
            for x in 0 ..< copyW {
                let s = ((source.y + y) * source.stride + (source.x + x)) * source.channels
                guard s + source.channels <= source.bytes.count else { continue }
                let d = ((target.y + y) * target.width + (target.x + x)) * 4
                let sa: UInt8 = source.channels == 4 ? source.bytes[s + 3] : 255
                blendPixel(
                    rgba: (source.bytes[s], source.bytes[s + 1], source.bytes[s + 2]),
                    alpha: sa,
                    into: &dst,
                    at: d,
                    alphaBlend: target.alphaBlend
                )
            }
        }
    }

    private static func blendPixel(
        rgba: (UInt8, UInt8, UInt8),
        alpha sa: UInt8,
        into dst: inout [UInt8],
        at d: Int,
        alphaBlend: Bool
    ) {
        if !alphaBlend || sa == 255 {
            dst[d] = rgba.0
            dst[d + 1] = rgba.1
            dst[d + 2] = rgba.2
            dst[d + 3] = sa
            return
        }
        guard sa > 0 else { return }
        let inv = 255 - Int(sa)
        let da = Int(dst[d + 3])
        let outA = Int(sa) + (da * inv + 127) / 255
        guard outA > 0 else { return }
        func mix(_ sc: UInt8, _ dc: UInt8) -> UInt8 {
            let num = Int(sc) * Int(sa) + (Int(dc) * da * inv + 127) / 255
            return UInt8(min(max((num + outA / 2) / outA, 0), 255))
        }
        dst[d] = mix(rgba.0, dst[d])
        dst[d + 1] = mix(rgba.1, dst[d + 1])
        dst[d + 2] = mix(rgba.2, dst[d + 2])
        dst[d + 3] = UInt8(min(outA, 255))
    }
}
