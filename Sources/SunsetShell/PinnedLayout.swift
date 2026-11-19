import CoreGraphics

/// Where the tiles of the Pinned grid are (roadmap 0021, P-b; the owner, 2026-11-17): four columns that share the width,
/// each tile between a least and a most width and of one height ("not necessarily a square"); three, two, then one column
/// as the sidebar narrows, so that no tile is under its least width; rows as needed for the twelve there can be.
struct PinnedLayout: Equatable {
    static let widths: ClosedRange<CGFloat> = 40 ... 120
    static let height: CGFloat = 36
    /// The gap when none is given; the grid gives the rows' spacing (roadmap 0038 D).
    static let gap: CGFloat = 6
    static let mostColumns = 4

    let count: Int
    let columns: Int
    let tile: CGSize
    /// Between two tiles, across and down.
    let gap: CGFloat

    init(width: CGFloat, count: Int, gap: CGFloat = Self.gap) {
        self.gap = gap
        self.count = max(count, 0)
        var columns = Self.mostColumns
        while columns > 1, (width - CGFloat(columns - 1) * gap) / CGFloat(columns) < Self.widths.lowerBound {
            columns -= 1
        }
        self.columns = columns
        let share = (width - CGFloat(columns - 1) * gap) / CGFloat(columns)
        tile = CGSize(width: min(max(share, Self.widths.lowerBound), Self.widths.upperBound), height: Self.height)
    }

    var rows: Int {
        (count + columns - 1) / columns
    }
    var height: CGFloat {
        rows == 0 ? 0 : CGFloat(rows) * Self.height + CGFloat(rows - 1) * gap
    }

    func frame(of index: Int) -> CGRect {
        CGRect(
            x: CGFloat(index % columns) * (tile.width + gap),
            y: CGFloat(index / columns) * (Self.height + gap),
            width: tile.width,
            height: tile.height
        )
    }
}
