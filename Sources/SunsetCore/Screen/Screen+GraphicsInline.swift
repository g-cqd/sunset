/// Sixel (`DCS P1;P2;P3 q <data> ST`) and iTerm2 inline image (`OSC 1337 ; File=...`) placement on `Screen`
/// (roadmap 0010 F). Both store bounded `TerminalImage` entries into `TerminalGraphics` and place them at the cursor
/// using the same `ImagePlacement` pipeline drawn identically by CPU and Metal renderers.
extension Screen {
    /// Decodes a completed Sixel DCS payload and places the resulting RGBA image at the cursor.
    mutating func finishSixel(_ bytes: ArraySlice<UInt8>) {
        let bg = palette.resolve(pen.background) ?? palette.background
        guard
            let decoded = SixelDecoder.decode(
                bytes,
                transparentBackground: graphics.sixelTransparent,
                background: bg
            )
        else { return }
        let cellW = max(graphics.cellWidth, 1)
        let cellH = max(graphics.cellHeight, 1)
        let cols = min(max((decoded.width + cellW - 1) / cellW, 1), TerminalGraphics.sideLimit)
        let down = min(max((decoded.height + cellH - 1) / cellH, 1), TerminalGraphics.sideLimit)
        storeAndPlaceInline(
            format: .rgba,
            sourceSize: (decoded.width, decoded.height),
            pixels: decoded.rgba,
            cells: (cols, down),
            drawSize: (decoded.width, decoded.height),
            carriageReturnAfter: true
        )
    }

    /// Parses and places an iTerm2 inline PNG image (`OSC 1337 ; File=...`).
    mutating func iTermInlineImage(from bytes: ArraySlice<UInt8>) {
        guard let request = ITermImageRequest.parse(bytes, maxBytes: graphics.quota) else { return }
        let sized = request.resolvedSize(
            columns: columns,
            rows: rows,
            cellWidth: graphics.cellWidth,
            cellHeight: graphics.cellHeight
        )
        storeAndPlaceInline(
            format: .png,
            sourceSize: (request.pixelWidth, request.pixelHeight),
            pixels: request.data,
            cells: sized.cells,
            drawSize: sized.pixels,
            carriageReturnAfter: false
        )
    }

    private mutating func storeAndPlaceInline(
        format: TerminalImage.Format,
        sourceSize: (width: Int, height: Int),
        pixels: [UInt8],
        cells: (columns: Int, rows: Int),
        drawSize: (width: Int, height: Int),
        carriageReturnAfter: Bool
    ) {
        let image = TerminalImage(
            id: graphics.nextAnonymousID(),
            format: format,
            width: sourceSize.width,
            height: sourceSize.height,
            pixels: pixels,
            order: graphics.nextOrder()
        )
        let shown = graphics.placements.count
        guard graphics.store(image) else { return }
        let placement = ImagePlacement(
            image: image.id,
            placement: 0,
            stableLine: cursorStableLine,
            column: column,
            columns: cells.columns,
            rows: cells.rows,
            width: drawSize.width,
            height: drawSize.height,
            sourceX: 0,
            sourceY: 0,
            sourceWidth: image.width,
            sourceHeight: image.height,
            offsetX: 0,
            offsetY: 0,
            layer: 0
        )
        graphics.place(placement)
        let redrawStart = graphics.placements.count != shown + 1 ? 0 : row
        markDirty(redrawStart ... min(row + cells.rows - 1, rows - 1))
        let startCol = column
        for _ in 0 ..< max(cells.rows - 1, 0) { lineFeed() }
        if carriageReturnAfter {
            lineFeed()
            column = 0
        } else {
            column = min(startCol + cells.columns, columns - 1)
        }
        pendingWrap = false
    }
}
