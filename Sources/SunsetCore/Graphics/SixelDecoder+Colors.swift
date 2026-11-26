/// Sixel palette defaults and DEC HLS-to-RGB conversion helpers for `SixelDecoder`.
extension SixelDecoder {
    /// Standard VT340 16-color default table packed as `0xRRGGBB`, padded to `maxColors`.
    private static let vt340Hex: [UInt32] = [
        0x000000, 0x3333CC, 0xCC2121, 0x33CC33, 0xCC33CC, 0x33CCCC, 0xCCCC33, 0x878787,
        0x424242, 0x545499, 0x994242, 0x549954, 0x995499, 0x549999, 0x999954, 0xCCCCCC
    ]

    static func defaultPalette() -> [RGB] {
        var colors = [RGB](repeating: RGB(0, 0, 0), count: maxColors)
        for (index, hex) in vt340Hex.enumerated() {
            colors[index] = RGB(UInt8(hex >> 16), UInt8((hex >> 8) & 0xFF), UInt8(hex & 0xFF))
        }
        return colors
    }

    /// Converts DEC VT340 HLS (hue 0=blue, 120=red, 240=green; lightness/saturation 0...100) to RGB.
    static func hlsToRGB(hue: Int, lightness: Int, saturation: Int) -> RGB {
        let l = Double(min(max(lightness, 0), 100)) / 100.0
        let s = Double(min(max(saturation, 0), 100)) / 100.0
        let maxC = l <= 0.5 ? l * (1.0 + s) : l + s - l * s
        let minC = 2.0 * l - maxC
        let h = Double(((hue - 120) % 360 + 360) % 360)
        func component(_ offset: Double) -> UInt8 {
            var t = (h + offset).truncatingRemainder(dividingBy: 360.0)
            if t < 0 { t += 360.0 }
            let value =
                if t < 60.0 {
                    minC + (maxC - minC) * t / 60.0
                } else if t < 180.0 {
                    maxC
                } else if t < 240.0 {
                    minC + (maxC - minC) * (240.0 - t) / 60.0
                } else {
                    minC
                }
            return UInt8(min(max((value * 255.0).rounded(), 0.0), 255.0))
        }
        return RGB(component(120.0), component(0.0), component(-120.0))
    }
}
