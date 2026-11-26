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
        pendingWrap = false
        if carriageReturnAfter {
            lineFeed()
            column = 0
        } else {
            // As iTerm2 leaves it: on the image's last row, just past it; past the right edge (the next character wraps)
            // when the image reaches it.
            let end = startCol + cells.columns
            column = min(end, columns - 1)
            pendingWrap = end >= columns && modes.autoWrap
        }
    }

    /// iTerm2's file in parts (`MultipartFile=<arguments>`, `FilePart=<base64>`…, `FileEnd`), what `imgcat` sends unless
    /// asked for `--legacy`: the parts' base64 is kept, bounded by the image quota, and read as `File=` at the end. A part
    /// or an end with no file begun is ignored; parts past the quota drop the file. True when `rest` was one of these.
    mutating func iTermFileInParts(_ rest: ArraySlice<UInt8>) -> Bool {
        let (start, part, end) = (Array("MultipartFile=".utf8), Array("FilePart=".utf8), Array("FileEnd".utf8))
        if rest.starts(with: start) {
            graphics.iTermParts = (Array(rest.dropFirst(start.count)), [])
        } else if rest.starts(with: part) {
            guard var parts = graphics.iTermParts else { return true }
            let more = rest.dropFirst(part.count)
            // Base64 is 4 characters for 3 bytes: past this, the file could not fit the quota.
            guard parts.base64.count + more.count <= graphics.quota / 3 * 4 + 4 else {
                graphics.iTermParts = nil
                return true
            }
            parts.base64.append(contentsOf: more)
            graphics.iTermParts = parts
        } else if rest.elementsEqual(end) {
            guard let parts = graphics.iTermParts else { return true }
            graphics.iTermParts = nil
            guard !parts.base64.isEmpty else { return true }
            iTermInlineImage(from: (parts.arguments + [0x3A] + parts.base64)[...])
        } else {
            return false
        }
        return true
    }
}
