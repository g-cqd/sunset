internal import SunsetCore

/// Images on the screen (ADR-0117): each drawn a row at a time, as text is, so a row drawn again (changed, scrolled in) has its
/// slice of every image on it; below the text when the program asked (`z` negative), above it otherwise.
extension CPURenderer {
    /// The placements on the lines the frame shows, their images made ready (read, scaled) the first time.
    func prepareImages(_ screen: Screen, firstLine: Int) {
        shownImages.removeAll(keepingCapacity: true)
        let graphics = screen.graphics
        guard !graphics.placements.isEmpty else { return }
        if imageTable.bytes > imageTableByteLimit { imageTable.startAgain(generation: GlyphGenerations.next()) }
        let lines = firstLine ..< firstLine + screen.rows
        for placement in graphics.placements {
            guard let top = screen.absoluteLine(ofStable: placement.stableLine),
                top < lines.upperBound, top + placement.rows > lines.lowerBound,
                let image = graphics.images[placement.image],
                let number = imageTable.number(
                    of: image,
                    width: placement.width,
                    height: placement.height,
                    decoder: imageDecoder
                )
            else { continue }
            shownImages.append(
                ShownImage(
                    number: number,
                    x: metrics.paddingX + placement.column * metrics.cellWidth,
                    top: top,
                    rows: placement.rows,
                    width: min(placement.width, placement.columns * metrics.cellWidth),
                    height: min(placement.height, placement.rows * metrics.cellHeight),
                    layer: placement.layer
                )
            )
        }
    }

    /// The slices of the images on `row` that go `below` the text, or above it.
    func drawImages(row: Int, below: Bool, frame: Frame, surface: inout Surface) {
        guard !shownImages.isEmpty else { return }
        let line = frame.firstLine + row
        let y = metrics.originY + row * metrics.cellHeight
        for shown in shownImages where (shown.layer < 0) == below && line >= shown.top && line < shown.top + shown.rows
        {
            let sourceY = (line - shown.top) * metrics.cellHeight
            let x0 = max(shown.x, 0)
            let x1 = min(shown.x + shown.width, surface.width)
            let y1 = min(y + min(metrics.cellHeight, shown.height - sourceY), surface.height)
            guard x0 < x1, y < y1 else { continue }
            let (place, size) = ((x: x0, y: y), (width: x1 - x0, height: y1 - y))
            if surface.records {
                surface.recorded.append(
                    DrawOp(
                        x: Int32(place.x),
                        y: Int32(place.y),
                        width: Int32(size.width),
                        height: Int32(size.height),
                        color: 0,
                        glyph: DrawOp.imageMark | shown.number,
                        sourceX: Int32(x0 - shown.x),
                        sourceY: Int32(sourceY)
                    )
                )
                continue
            }
            ImageBlend.draw(
                imageTable.images[Int(shown.number)],
                from: (x0 - shown.x, sourceY),
                to: place,
                size: size,
                into: &surface,
                translucent: translucent
            )
        }
    }
}
