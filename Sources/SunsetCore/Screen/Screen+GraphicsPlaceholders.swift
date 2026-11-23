/// kitty's Unicode placeholders (roadmap 0010 E): a cell holding `U+10EEEE` draws a piece of an image given a virtual
/// placement. Its foreground colour names the image (24 bits, or a palette index), its underline colour the placement; its
/// marks say its row, its column and the image id's highest byte. A mark left out is taken from the cell before, when that
/// cell continues it, as kitty does.
extension Screen {
    /// The character a placeholder cell starts with.
    public static let placeholder: UInt32 = 0x10EEEE

    /// Whether `cell` is a placeholder cell, which the renderer draws no glyph for.
    public func isImagePlaceholder(_ cell: Cell) -> Bool {
        cell.isCluster ? clusters.scalars(of: cell.scalar).first == Self.placeholder : cell.scalar == Self.placeholder
    }

    /// The runs of placeholder cells on `line`, counted from the oldest line of the history.
    func placeholderRuns(line: Int) -> [PlaceholderRun] {
        guard line >= 0, line < absoluteLineCount else { return [] }
        let history = scrollback.count
        var runs: [PlaceholderRun] = []
        // The cell before, as read: what a cell with marks left out continues.
        var previous: PlaceholderCell?
        for column in 0 ..< columns {
            let cell = line < history ? scrollbackCell(line: line, column: column) : grid[line - history, column]
            guard isImagePlaceholder(cell), let read = placeholder(cell, after: previous) else {
                previous = nil
                continue
            }
            previous = read
            let image = read.id
            if var last = runs.last, last.image == image, last.placement == read.placement, last.imageRow == read.row,
                last.column + last.count == column, last.imageColumn + last.count == read.column
            {
                last.count += 1
                runs[runs.count - 1] = last
            } else {
                runs.append(
                    PlaceholderRun(
                        image: image,
                        placement: read.placement,
                        imageRow: read.row,
                        imageColumn: read.column,
                        column: column,
                        count: 1
                    )
                )
            }
        }
        return runs
    }

    /// What placeholder `cell` says, its left-out marks taken from `previous` when that cell names the same image and placement;
    /// nil when its colour names no image.
    private func placeholder(_ cell: Cell, after previous: PlaceholderCell?) -> PlaceholderCell? {
        let style = style(of: cell)
        guard let image = Self.number(style.foreground), image != 0 else { return nil }
        let placement = Self.number(style.underlineColor) ?? 0
        let marks =
            cell.isCluster ? clusters.scalars(of: cell.scalar).dropFirst().compactMap(PlaceholderDiacritics.number) : []
        let same = previous.flatMap { $0.image == image && $0.placement == placement ? $0 : nil }
        let row = marks.first ?? same?.row ?? 0
        // The column and the highest byte continue the cell before only on its row, one column on.
        let before = same.flatMap { $0.row == row ? $0 : nil }
        let column = marks.count > 1 ? marks[1] : before.map { $0.column + 1 } ?? 0
        let high = marks.count > 2 ? UInt32(marks[2]) : before.flatMap { column == $0.column + 1 ? $0.high : nil } ?? 0
        return PlaceholderCell(image: image, placement: placement, row: row, column: column, high: high)
    }

    /// The number a colour carries: its 24 bits, or its palette index; nil for the default colour.
    private static func number(_ color: Color) -> UInt32? {
        switch color.raw >> 24 {
            case 1, 2: color.raw & 0xFF_FFFF
            default: nil
        }
    }
}
