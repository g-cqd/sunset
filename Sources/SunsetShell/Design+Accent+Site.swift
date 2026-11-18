import Foundation

/// The accent from the site shown (`appearance.accent` "site"; roadmap 0047 H): its declared theme colour, else its icon's
/// colour, when either stands out on a window (luminance in `readable`, colourful enough); else none, and the system's.
extension Design.Accent {
    /// How colourful a colour must be (its chroma, 0 to 1) to be an accent: a grey is not one.
    static let minimumChroma = 0.2

    package static func site(theme: [UInt8]?, icon: [UInt8]?) -> Self? {
        for rgb in [theme, icon].compactMap(\.self) where stands(rgb) {
            return .color(red: rgb[0], green: rgb[1], blue: rgb[2])
        }
        return nil
    }

    static func stands(_ rgb: [UInt8]) -> Bool {
        guard rgb.count >= 3 else { return false }
        return readable.contains(luminance(rgb)) && chroma(rgb) >= minimumChroma
    }

    static func chroma(_ rgb: [UInt8]) -> Double {
        let values = rgb.prefix(3).map { Double($0) / 255 }
        return (values.max() ?? 0) - (values.min() ?? 0)
    }

    /// The most common colourful colour of an image's RGBA pixels (alpha not premultiplied), quantised to 32 levels a
    /// channel; nil when none is colourful.
    package static func dominant(rgba: [UInt8]) -> [UInt8]? {
        var counts: [Int: (count: Int, sum: [Int])] = [:]
        var index = 0
        while index + 3 < rgba.count {
            let pixel = [rgba[index], rgba[index + 1], rgba[index + 2]]
            if rgba[index + 3] > 128, stands(pixel) {
                let key = Int(pixel[0] >> 3) << 10 | Int(pixel[1] >> 3) << 5 | Int(pixel[2] >> 3)
                var bucket = counts[key] ?? (0, [0, 0, 0])
                bucket.count += 1
                for channel in 0 ..< 3 { bucket.sum[channel] += Int(pixel[channel]) }
                counts[key] = bucket
            }
            index += 4
        }
        guard let best = counts.values.max(by: { $0.count < $1.count }) else { return nil }
        return best.sum.map { UInt8($0 / best.count) }
    }
}
