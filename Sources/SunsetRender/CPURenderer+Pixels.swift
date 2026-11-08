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
        if surface.records {
            surface.recorded.append(.fill(x: x0, y: y0, width: x1 - x0, height: y1 - y0, color: color))
            return
        }
        let stride = surface.width
        // One access to the buffer for the whole rectangle, and one store loop a row: with the array's subscript every pixel paid for a uniqueness check and
        // a bounds check (measured: a blank retina frame was 58 M instructions, 19 a pixel).
        surface.pixels.withUnsafeMutableBufferPointer { pixels in
            guard let base = pixels.baseAddress else { return }
            for row in y0 ..< y1 { unsafe (base + row * stride + x0).update(repeating: color, count: x1 - x0) }
        }
    }

    /// Blends the coverage of glyph number `glyph` of `table` over what is there, inside the cell(s) it belongs to.
    func blit(_ glyph: UInt32, of table: GlyphTable, into surface: inout Surface, cell box: Box, color: RGB) {
        let (cellX, cellY, cellWidth) = (box.x, box.y, box.width)
        let place = table.placements[Int(glyph) - 1]
        let (left, top, width, height) = (Int(place.left), Int(place.top), Int(place.width), Int(place.height))
        // The part of the bitmap that is inside the cell(s) and the surface, worked out once: rows `rows`, columns `columns` of the bitmap.
        let leftEdge = max(cellX, 0)
        let rightEdge = min(cellX + cellWidth, surface.width)
        let topEdge = max(cellY, 0)
        let bottomEdge = min(cellY + metrics.cellHeight, surface.height)
        let columns = max(leftEdge - (cellX + left), 0) ..< min(rightEdge - (cellX + left), width)
        let rows = max(topEdge - (cellY + top), 0) ..< min(bottomEdge - (cellY + top), height)
        guard !columns.isEmpty, !rows.isEmpty else { return }
        let solid = Surface.pack(color)
        if surface.records {
            surface.recorded.append(
                DrawOp(
                    x: Int32(cellX + left + columns.lowerBound),
                    y: Int32(cellY + top + rows.lowerBound),
                    width: Int32(columns.count),
                    height: Int32(rows.count),
                    color: solid,
                    glyph: glyph,
                    sourceX: Int32(columns.lowerBound),
                    sourceY: Int32(rows.lowerBound)
                )
            )
            return
        }
        let bitmap = table[glyph]
        let stride = surface.width
        bitmap.coverage.withUnsafeBufferPointer { coverage in
            surface.pixels.withUnsafeMutableBufferPointer { pixels in
                guard let base = pixels.baseAddress, let source = coverage.baseAddress else { return }
                for row in rows {
                    let y = cellY + bitmap.top + row
                    let line = unsafe base + y * stride + cellX + bitmap.left
                    let alphas = unsafe source + row * bitmap.width
                    blendRow(
                        unsafe line + columns.lowerBound,
                        coverage: unsafe alphas + columns.lowerBound,
                        count: columns.count,
                        color: solid
                    )
                }
            }
        }
    }

    @inline(__always) private func blendRow(
        _ destination: UnsafeMutablePointer<UInt32>,
        coverage: UnsafePointer<UInt8>,
        count: Int,
        color: UInt32
    ) {
        if translucent {
            PixelKernels.blendPremultiplied(destination, coverage: coverage, count: count, color: color)
        } else {
            PixelKernels.blend(destination, coverage: coverage, count: count, color: color)
        }
    }

    /// The colours a style is drawn in, after inverse and faint.
    static func colors(of style: CellStyle, frame: Frame) -> (foreground: RGB, background: RGB) {
        var foreground = frame.palette.resolve(style.foreground) ?? frame.foreground
        var background = frame.palette.resolve(style.background) ?? frame.background
        if style.attributes.contains(.inverse) { swap(&foreground, &background) }
        if style.attributes.contains(.faint) { foreground = mix(foreground, background) }
        return (foreground, background)
    }

    static func mix(_ first: RGB, _ second: RGB) -> RGB {
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
