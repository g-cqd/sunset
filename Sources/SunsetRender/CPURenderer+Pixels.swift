internal import SunsetCore

/// Pixel work of the CPU renderer: fills, blending a glyph's coverage, decorations.
extension CPURenderer {
    // MARK: Pixels

    func fill(_ surface: inout Surface, x: Int, y: Int, width: Int, height: Int, color: UInt32) {
        let x0 = max(0, x)
        let x1 = min(surface.width, x + width)
        let y0 = max(0, y)
        let y1 = min(surface.height, y + height)
        guard x0 < x1, y0 < y1 else { return }
        for row in y0 ..< y1 {
            let base = row * surface.width
            for column in x0 ..< x1 { surface.pixels[base + column] = color }
        }
    }

    /// Blends the glyph's coverage over what is there, inside the cell(s) it belongs to.
    func blit(
        _ bitmap: GlyphBitmap,
        into surface: inout Surface,
        cellX: Int,
        cellY: Int,
        cellWidth: Int,
        color: RGB
    ) {
        for row in 0 ..< bitmap.height {
            let y = cellY + bitmap.top + row
            guard y >= cellY, y < cellY + metrics.cellHeight, y < surface.height else { continue }
            for column in 0 ..< bitmap.width {
                let x = cellX + bitmap.left + column
                guard x >= cellX, x < cellX + cellWidth, x < surface.width else { continue }
                let alpha = Int(bitmap.coverage[row * bitmap.width + column])
                if alpha == 0 { continue }
                let index = y * surface.width + x
                surface.pixels[index] = alpha == 255 ? Surface.pack(color) : blend(surface.pixels[index], color, alpha)
            }
        }
    }

    @inline(__always) private func blend(_ below: UInt32, _ color: RGB, _ alpha: Int) -> UInt32 {
        let inverse = 255 - alpha
        let red = (Int(color.red) * alpha + Int(below & 0xFF) * inverse + 127) / 255
        let green = (Int(color.green) * alpha + Int((below >> 8) & 0xFF) * inverse + 127) / 255
        let blue = (Int(color.blue) * alpha + Int((below >> 16) & 0xFF) * inverse + 127) / 255
        return Surface.pack(RGB(UInt8(red), UInt8(green), UInt8(blue)))
    }

    /// The colours a style is drawn in, after inverse and faint.
    func colors(of style: CellStyle, frame: Frame) -> (foreground: RGB, background: RGB) {
        let palette = frame.screen.palette
        var foreground = palette.resolve(style.foreground) ?? frame.foreground
        var background = palette.resolve(style.background) ?? frame.background
        if style.attributes.contains(.inverse) { swap(&foreground, &background) }
        if style.attributes.contains(.faint) { foreground = mix(foreground, background) }
        return (foreground, background)
    }

    func mix(_ first: RGB, _ second: RGB) -> RGB {
        RGB(
            UInt8((Int(first.red) + Int(second.red)) / 2),
            UInt8((Int(first.green) + Int(second.green)) / 2),
            UInt8((Int(first.blue) + Int(second.blue)) / 2)
        )
    }

    // MARK: Decorations

    func drawDecorations(_ style: CellStyle, box: Box, surface: inout Surface, line: RGB, strike: RGB) {
        let (x, y, width) = (box.x, box.y, box.width)
        let thickness = metrics.lineThickness
        let packedLine = Surface.pack(line)
        switch style.underline {
            case .none: break
            case .single:
                fill(&surface, x: x, y: y + metrics.underlineY, width: width, height: thickness, color: packedLine)
            case .double:
                fill(&surface, x: x, y: y + metrics.underlineY, width: width, height: thickness, color: packedLine)
                fill(
                    &surface,
                    x: x,
                    y: max(0, y + metrics.underlineY - 2 * thickness),
                    width: width,
                    height: thickness,
                    color: packedLine
                )
            case .curly:
                let wave = [0, 1, 2, 1]
                for offset in 0 ..< width {
                    fill(
                        &surface,
                        x: x + offset,
                        y: y + metrics.underlineY - 1 + wave[offset % 4],
                        width: 1,
                        height: thickness,
                        color: packedLine
                    )
                }
            case .dotted:
                for offset in stride(from: 0, to: width, by: 2) {
                    fill(
                        &surface,
                        x: x + offset,
                        y: y + metrics.underlineY,
                        width: 1,
                        height: thickness,
                        color: packedLine
                    )
                }
            case .dashed:
                for offset in 0 ..< width where offset % 4 != 3 {
                    fill(
                        &surface,
                        x: x + offset,
                        y: y + metrics.underlineY,
                        width: 1,
                        height: thickness,
                        color: packedLine
                    )
                }
        }
        if style.attributes.contains(.strikethrough) {
            fill(&surface, x: x, y: y + metrics.strikeY, width: width, height: thickness, color: Surface.pack(strike))
        }
        if style.attributes.contains(.overline) {
            fill(&surface, x: x, y: y + metrics.overlineY, width: width, height: thickness, color: Surface.pack(strike))
        }
    }
}
