import CoreGraphics

/// Where each icon of the picker's grid is: cells of one size in as many columns as fit, centred. The grid is one view
/// that draws the cells in sight and finds a cell from a point by this arithmetic; nothing is made for the cells out of
/// sight.
struct IconGridLayout: Equatable {
    /// A cell with the gap to the next.
    static let pitch = CGSize(width: 34, height: 32)
    /// What is drawn of a cell (its highlight): the pitch without the gap.
    static let cell = CGSize(width: 30, height: 28)

    let count: Int
    let columns: Int
    /// From the view's edge to the first column.
    let inset: CGFloat

    init(width: CGFloat, count: Int) {
        self.count = max(count, 0)
        columns = max(Int(width / Self.pitch.width), 1)
        inset = max((width - CGFloat(columns) * Self.pitch.width) / 2, 0)
    }

    var rows: Int { (count + columns - 1) / columns }
    var height: CGFloat { CGFloat(rows) * Self.pitch.height }

    /// The cell's pitch: its place, gap included.
    func rect(of index: Int) -> CGRect {
        CGRect(
            x: inset + CGFloat(index % columns) * Self.pitch.width,
            y: CGFloat(index / columns) * Self.pitch.height,
            width: Self.pitch.width,
            height: Self.pitch.height
        )
    }

    /// The cell under a point; nil in the margins and past the last cell.
    func index(at point: CGPoint) -> Int? {
        guard point.x >= inset, point.y >= 0 else { return nil }
        let column = Int((point.x - inset) / Self.pitch.width)
        let index = Int(point.y / Self.pitch.height) * columns + column
        return column < columns && index < count ? index : nil
    }

    /// The cells of the rows a rectangle touches.
    func indices(in rect: CGRect) -> Range<Int> {
        guard rect.maxY > 0, rect.minY < height, count > 0 else { return 0 ..< 0 }
        let first = max(Int(rect.minY / Self.pitch.height), 0)
        let last = min(Int((rect.maxY - 0.001) / Self.pitch.height), rows - 1)
        guard first <= last else { return 0 ..< 0 }
        return first * columns ..< min((last + 1) * columns, count)
    }
}
