internal import SunsetCore

/// Images on the screen (ADR-0117): each drawn a row at a time, as text is, so a row drawn again (changed, scrolled in) has its
/// slice of every image on it, in its layer (`ImageLayer`).
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
                    source: ImageCrop(
                        x: placement.sourceX,
                        y: placement.sourceY,
                        width: placement.sourceWidth,
                        height: placement.sourceHeight
                    ),
                    width: placement.width,
                    height: placement.height,
                    decoder: imageDecoder
                )
            else { continue }
            shownImages.append(
                ShownImage(
                    number: number,
                    x: metrics.paddingX + placement.column * metrics.cellWidth + placement.offsetX,
                    top: top,
                    offsetY: placement.offsetY,
                    rows: placement.rows,
                    width: min(placement.width, placement.columns * metrics.cellWidth - placement.offsetX),
                    height: min(placement.height, placement.rows * metrics.cellHeight - placement.offsetY),
                    layer: ImageLayer(z: placement.layer)
                )
            )
        }
    }

    /// Whether `row` has a slice of an image in `layer`.
    func hasImages(row: Int, in layer: ImageLayer, frame: Frame) -> Bool {
        let line = frame.firstLine + row
        return shownImages.contains { $0.layer == layer && line >= $0.top && line < $0.top + $0.rows }
    }

    /// The slices of the images in `layer` on `row`: the part of each image between the row's top and bottom, the image
    /// starting `offsetY` pixels into its first line.
    func drawImages(row: Int, layer: ImageLayer, frame: Frame, surface: inout Surface) {
        guard !shownImages.isEmpty else { return }
        let line = frame.firstLine + row
        let y = metrics.originY + row * metrics.cellHeight
        for shown in shownImages where shown.layer == layer && line >= shown.top && line < shown.top + shown.rows {
            // The row's pixels, counted from the image's first line; the image's, from the same place.
            let rowStart = (line - shown.top) * metrics.cellHeight
            let start = max(rowStart, shown.offsetY)
            let end = min(rowStart + metrics.cellHeight, shown.offsetY + shown.height)
            let x0 = max(shown.x, 0)
            let x1 = min(shown.x + shown.width, surface.width)
            let top = y + start - rowStart
            let bottom = min(top + end - start, surface.height)
            guard x0 < x1, top < bottom else { continue }
            let (place, size) = ((x: x0, y: top), (width: x1 - x0, height: bottom - top))
            let source = (x: x0 - shown.x, y: start - shown.offsetY)
            if surface.records {
                surface.recorded.append(
                    DrawOp(
                        x: Int32(place.x),
                        y: Int32(place.y),
                        width: Int32(size.width),
                        height: Int32(size.height),
                        color: 0,
                        glyph: DrawOp.imageMark | shown.number,
                        sourceX: Int32(source.x),
                        sourceY: Int32(source.y)
                    )
                )
                continue
            }
            ImageBlend.draw(
                imageTable.images[Int(shown.number)],
                from: source,
                to: place,
                size: size,
                into: &surface,
                translucent: translucent
            )
        }
    }
}
