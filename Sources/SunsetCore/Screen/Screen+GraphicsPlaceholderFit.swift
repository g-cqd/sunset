/// What placeholder cells draw (roadmap 0010 E): runs of cells stacked row on row make a rectangle of an image's virtual cells;
/// the image, fitted into its virtual placement's cells keeping its proportions and centred, is drawn over the part of it the
/// rectangle covers. A rectangle is followed above and below the lines asked for, so its part, and the image scaled for it,
/// stay the same while it scrolls.
extension Screen {
    /// What the placeholder cells on `lines` (counted from the oldest line of the history) draw, as placements; none when no
    /// image has a virtual placement.
    public func placeholderPlacements(lines: Range<Int>) -> [ImagePlacement] {
        guard !graphics.virtualPlacements.isEmpty else { return [] }
        var shown: [ImagePlacement] = []
        var done: Set<Int> = []
        var read: [Int: [PlaceholderRun]] = [:]
        func runs(_ line: Int) -> [PlaceholderRun] {
            if let known = read[line] { return known }
            let made = placeholderRuns(line: line)
            read[line] = made
            return made
        }
        let visible = lines.clamped(to: 0 ..< absoluteLineCount)
        for line in visible {
            for (index, run) in runs(line).enumerated() where !done.contains(line << 16 | index) {
                // The rectangle the run is part of: the runs above it and below it that continue it.
                var (top, bottom) = (line, line)
                var first = run
                while first.imageRow > 0, let above = runs(top - 1).first(where: { $0.isAbove(first) }) {
                    top -= 1
                    first = above
                }
                var last = run
                while let below = runs(bottom + 1).firstIndex(where: last.isAbove) {
                    bottom += 1
                    last = runs(bottom)[below]
                    if visible.contains(bottom) { done.insert(bottom << 16 | below) }
                }
                if let placement = fitted(first, lines: top ... bottom) { shown.append(placement) }
            }
        }
        return shown
    }

    /// The part of the image `first` names that its rectangle of `lines` covers, as a placement; nil when the image or its virtual
    /// placement is gone, or the rectangle covers only the margins left by fitting it.
    private func fitted(_ first: PlaceholderRun, lines: ClosedRange<Int>) -> ImagePlacement? {
        guard let virtual = graphics.virtual(image: first.image, placement: first.placement),
            let image = graphics.images[first.image], image.width > 0, image.height > 0
        else { return nil }
        let (cellWidth, cellHeight) = (Double(max(graphics.cellWidth, 1)), Double(max(graphics.cellHeight, 1)))
        // The image in its virtual cells: as large as fits, its proportions kept, centred.
        let grid = (width: Double(virtual.columns) * cellWidth, height: Double(virtual.rows) * cellHeight)
        let scale = min(grid.width / Double(image.width), grid.height / Double(image.height))
        let drawn = (width: Double(image.width) * scale, height: Double(image.height) * scale)
        let origin = ((grid.width - drawn.width) / 2, (grid.height - drawn.height) / 2)
        // The rectangle in the same space, and what of the image falls in it.
        let left = Double(first.imageColumn) * cellWidth
        let top = Double(first.imageRow) * cellHeight
        let right = left + Double(first.count) * cellWidth
        let bottom = top + Double(lines.count) * cellHeight
        let x0 = max(left, origin.0).rounded()
        let x1 = min(right, origin.0 + drawn.width).rounded()
        let y0 = max(top, origin.1).rounded()
        let y1 = min(bottom, origin.1 + drawn.height).rounded()
        guard x0 < x1, y0 < y1 else { return nil }
        let (across, down) = (Int(x0 - left), Int(y0 - top))
        let (column, line) = (first.column + across / Int(cellWidth), lines.lowerBound + down / Int(cellHeight))
        let sourceX = min(Int(((x0 - origin.0) / scale).rounded()), image.width - 1)
        let sourceY = min(Int(((y0 - origin.1) / scale).rounded()), image.height - 1)
        return ImagePlacement(
            image: first.image,
            placement: first.placement,
            stableLine: scrollback.evicted + line,
            column: column,
            columns: first.column + first.count - column,
            rows: lines.upperBound + 1 - line,
            width: Int(x1 - x0),
            height: Int(y1 - y0),
            sourceX: sourceX,
            sourceY: sourceY,
            sourceWidth: max(min(Int(((x1 - x0) / scale).rounded()), image.width - sourceX), 1),
            sourceHeight: max(min(Int(((y1 - y0) / scale).rounded()), image.height - sourceY), 1),
            offsetX: across % Int(cellWidth),
            offsetY: down % Int(cellHeight),
            layer: virtual.layer
        )
    }
}
