/// The size of a cell in pixels and where the decorations go inside it.
public struct RenderMetrics: Sendable, Equatable {
    public var cellWidth: Int
    public var cellHeight: Int
    /// Space around the grid, in pixels.
    public var paddingX = 0
    public var paddingY = 0
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

    /// The surface size for a grid of `columns` x `rows`.
    public func surfaceSize(columns: Int, rows: Int) -> (width: Int, height: Int) {
        (columns * cellWidth + 2 * paddingX, rows * cellHeight + 2 * paddingY)
    }
}
