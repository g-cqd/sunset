/// The size of a cell in pixels and where the decorations go inside it.
public struct RenderMetrics: Sendable, Equatable {
    public var cellWidth: Int
    public var cellHeight: Int
    /// Space around the grid, in pixels.
    public var paddingX = 0
    public var paddingY = 0
    /// Extra space above the grid only, in pixels (the strip of a window with no title bar that drags it).
    public var topInset = 0
    /// Rows from the top of a cell to the underline, the strikethrough and the overline; and the thickness of a line.
    public var underlineY: Int
    public var strikeY: Int
    public var overlineY = 0
    public var lineThickness = 1

    public init(cellWidth: Int, cellHeight: Int) {
        precondition(cellWidth >= 2 && cellHeight >= 4, "a cell is at least 2x4 pixels")
        self.cellWidth = cellWidth
        self.cellHeight = cellHeight
        underlineY = cellHeight - max(2, cellHeight / 8)
        strikeY = cellHeight / 2
    }

    /// Where the first row of the grid starts, in pixels from the top of the surface.
    public var originY: Int { paddingY + topInset }

    /// The surface size for a grid of `columns` x `rows`.
    public func surfaceSize(columns: Int, rows: Int) -> (width: Int, height: Int) {
        (columns * cellWidth + 2 * paddingX, rows * cellHeight + 2 * paddingY + topInset)
    }
}

extension RenderMetrics {
    /// The cell under a pixel of the surface; a pixel in the padding or outside the grid is the nearest cell on the edge (a drag that leaves the window still
    /// reports the edge).
    public func cell(atPixelX x: Int, pixelY y: Int, columns: Int, rows: Int) -> (column: Int, row: Int) {
        let column = min(max((x - paddingX).floorDivided(by: cellWidth), 0), max(columns - 1, 0))
        let row = min(max((y - originY).floorDivided(by: cellHeight), 0), max(rows - 1, 0))
        return (column, row)
    }

    /// A pixel of the surface as a pixel of the grid (the padding left out), kept inside the grid.
    public func gridPixel(x: Int, y: Int, columns: Int, rows: Int) -> (x: Int, y: Int) {
        (
            min(max(x - paddingX, 0), max(columns * cellWidth - 1, 0)),
            min(max(y - originY, 0), max(rows * cellHeight - 1, 0))
        )
    }
}

extension Int {
    /// Division that rounds toward negative infinity, so a pixel left of the grid is column -1, not 0.
    fileprivate func floorDivided(by divisor: Int) -> Int {
        let quotient = self / divisor
        return self % divisor < 0 ? quotient - 1 : quotient
    }
}
