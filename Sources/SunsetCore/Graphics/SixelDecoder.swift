/// Sixel DCS graphics decoder (DEC PPLv2 / roadmap 0010 F): parses the payload of `DCS P1;P2;P3 q <data> ST` into
/// straight RGBA pixels (8 bits/channel, top-to-bottom), strictly bounded by dimension and pixel caps so hostile or
/// malformed streams never trap or exhaust memory.
enum SixelDecoder {
    struct Output: Sendable, Equatable {
        let width: Int
        let height: Int
        let rgba: [UInt8]
    }

    /// Maximum pixel count decoded from a single Sixel sequence (16M px = 64 MiB RGBA, matching `RenderImage.pixelLimit`).
    static let maxPixels = 1 << 24
    /// Maximum side length accepted for a Sixel canvas.
    static let maxSide = 4_096
    /// Maximum palette register count (VT340 supports 256; xterm supports 1024).
    static let maxColors = 1_024

    /// Decodes a Sixel byte payload. `transparentBackground` is true when `P2 == 1` (unwritten pixels stay alpha 0).
    static func decode(
        _ data: ArraySlice<UInt8>,
        transparentBackground: Bool = false,
        background: RGB = RGB(0, 0, 0)
    ) -> Output? {
        var state = State(transparent: transparentBackground, background: background)
        state.parse(data)
        return state.finalize()
    }

    private struct State {
        let transparent: Bool
        let background: RGB
        var palette = SixelDecoder.defaultPalette()
        var colorIndex = 0
        var cursorX = 0
        var cursorY = 0
        var declaredWidth = 0
        var declaredHeight = 0
        var maxX = 0
        var maxY = 0
        var canvasWidth = 0
        var canvasHeight = 0
        var pixels: [UInt8] = []
        var overflowed = false

        mutating func parse(_ data: ArraySlice<UInt8>) {
            var index = data.startIndex
            let end = data.endIndex
            while index < end, !overflowed {
                let byte = data[index]
                index += 1
                switch byte {
                    case 0x3F ... 0x7E: drawSixel(byte - 0x3F, repeatCount: 1)
                    case UInt8(ascii: "!"):
                        let count = readNumber(in: data, from: &index)
                        if index < end, data[index] >= 0x3F, data[index] <= 0x7E {
                            let sixel = data[index] - 0x3F
                            index += 1
                            drawSixel(sixel, repeatCount: max(count, 1))
                        }
                    case UInt8(ascii: "$"): cursorX = 0
                    case UInt8(ascii: "-"):
                        cursorX = 0
                        cursorY += 6
                        if cursorY >= SixelDecoder.maxSide { overflowed = true }
                    case UInt8(ascii: "\""): parseRaster(in: data, from: &index)
                    case UInt8(ascii: "#"): parseColor(in: data, from: &index)
                    default: break
                }
            }
        }

        mutating func finalize() -> Output? {
            guard !overflowed else { return nil }
            let (width, height) = (max(maxX, declaredWidth), max(maxY, declaredHeight))
            guard width > 0, height > 0, width <= SixelDecoder.maxSide, height <= SixelDecoder.maxSide,
                width * height <= SixelDecoder.maxPixels
            else { return nil }
            ensureCanvas(width: width, height: height)
            guard !overflowed else { return nil }
            if width == canvasWidth, height == canvasHeight {
                return Output(width: width, height: height, rgba: pixels)
            }
            var out = [UInt8](repeating: 0, count: width * height * 4)
            let rowBytes = width * 4
            for row in 0 ..< height {
                let src = row * canvasWidth * 4
                out.replaceSubrange(row * rowBytes ..< (row + 1) * rowBytes, with: pixels[src ..< src + rowBytes])
            }
            return Output(width: width, height: height, rgba: out)
        }

        private mutating func parseRaster(in data: ArraySlice<UInt8>, from index: inout Int) {
            let params = readParams(in: data, from: &index, limit: 4)
            guard params.count >= 4, params[2] > 0, params[3] > 0 else { return }
            let (width, height) = (params[2], params[3])
            guard width <= SixelDecoder.maxSide, height <= SixelDecoder.maxSide,
                width * height <= SixelDecoder.maxPixels
            else {
                overflowed = true
                return
            }
            declaredWidth = max(declaredWidth, width)
            declaredHeight = max(declaredHeight, height)
            ensureCanvas(width: declaredWidth, height: declaredHeight)
        }

        private mutating func parseColor(in data: ArraySlice<UInt8>, from index: inout Int) {
            let params = readParams(in: data, from: &index, limit: 5)
            guard let register = params.first else { return }
            let slot = register % SixelDecoder.maxColors
            colorIndex = slot
            guard params.count >= 5 else { return }
            if params[1] == 2 {
                let red = UInt8(min(max(params[2], 0), 100) * 255 / 100)
                let green = UInt8(min(max(params[3], 0), 100) * 255 / 100)
                let blue = UInt8(min(max(params[4], 0), 100) * 255 / 100)
                palette[slot] = RGB(red, green, blue)
            } else if params[1] == 1 {
                palette[slot] = SixelDecoder.hlsToRGB(hue: params[2], lightness: params[3], saturation: params[4])
            }
        }

        private mutating func drawSixel(_ bits: UInt8, repeatCount: Int) {
            let endX = cursorX + repeatCount
            guard endX <= SixelDecoder.maxSide, cursorY + 6 <= SixelDecoder.maxSide else {
                overflowed = true
                return
            }
            if bits != 0 {
                if endX > canvasWidth || cursorY + 6 > canvasHeight {
                    ensureCanvas(width: max(canvasWidth, endX), height: max(canvasHeight, cursorY + 6))
                    guard !overflowed else { return }
                }
                let rgb = palette[colorIndex]
                for bit in 0 ..< 6 where (bits & (1 << bit)) != 0 {
                    let rowBase = (cursorY + bit) * canvasWidth * 4
                    for x in cursorX ..< endX {
                        let offset = rowBase + x * 4
                        pixels[offset] = rgb.red
                        pixels[offset + 1] = rgb.green
                        pixels[offset + 2] = rgb.blue
                        pixels[offset + 3] = 255
                    }
                    maxY = max(maxY, cursorY + bit + 1)
                }
            } else {
                maxY = max(maxY, cursorY + 6)
            }
            cursorX = endX
            maxX = max(maxX, endX)
        }

        private mutating func ensureCanvas(width neededW: Int, height neededH: Int) {
            guard neededW <= SixelDecoder.maxSide, neededH <= SixelDecoder.maxSide else {
                overflowed = true
                return
            }
            let newW =
                neededW <= canvasWidth ? canvasWidth : min(SixelDecoder.maxSide, max(neededW, canvasWidth * 2, 64))
            let newH =
                neededH <= canvasHeight ? canvasHeight : min(SixelDecoder.maxSide, max(neededH, canvasHeight * 2, 64))
            guard newW != canvasWidth || newH != canvasHeight else { return }
            guard newW * newH <= SixelDecoder.maxPixels else {
                overflowed = true
                return
            }
            var resized = [UInt8](repeating: 0, count: newW * newH * 4)
            if !transparent {
                for offset in stride(from: 0, to: resized.count, by: 4) {
                    resized[offset] = background.red
                    resized[offset + 1] = background.green
                    resized[offset + 2] = background.blue
                    resized[offset + 3] = 255
                }
            }
            let oldRowBytes = canvasWidth * 4
            if oldRowBytes > 0 {
                for row in 0 ..< canvasHeight {
                    let src = row * oldRowBytes
                    let dst = row * newW * 4
                    resized.replaceSubrange(dst ..< dst + oldRowBytes, with: pixels[src ..< src + oldRowBytes])
                }
            }
            (pixels, canvasWidth, canvasHeight) = (resized, newW, newH)
        }

        private func readNumber(in data: ArraySlice<UInt8>, from index: inout Int) -> Int {
            var value = 0
            while index < data.endIndex, data[index] >= 0x30, data[index] <= 0x39 {
                value = min(value * 10 + Int(data[index] - 0x30), SixelDecoder.maxSide + 1)
                index += 1
            }
            return value
        }

        private func readParams(in data: ArraySlice<UInt8>, from index: inout Int, limit: Int) -> [Int] {
            var values: [Int] = []
            while index < data.endIndex, values.count < limit {
                if data[index] >= 0x30, data[index] <= 0x39 {
                    values.append(readNumber(in: data, from: &index))
                } else if data[index] == UInt8(ascii: ";") {
                    if values.isEmpty { values.append(0) }
                    index += 1
                    continue
                } else {
                    break
                }
                guard index < data.endIndex, data[index] == UInt8(ascii: ";") else { break }
                index += 1
            }
            return values
        }
    }
}
