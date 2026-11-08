internal import SunsetCore

extension CPURenderer {
    /// Underlines the cells of the row that belong to the hovered link, unless they have an underline of their own. A pass over the row that only frames with a
    /// hovered link pay for; the common frame does no link work at all.
    func underlineHoveredLink(row: Int, frame: Frame, surface: inout Surface) {
        var column = 0
        while column < frame.columns {
            let cell = frame.cell(row: row, column: column)
            column += 1
            let style = frame.style(of: cell)
            guard style.link == frame.hoveredLink, style.underline == .none else { continue }
            var underlined = style
            underlined.underline = .single
            let span = cell.width == .wide && column < frame.columns ? 2 : 1
            let colors = Self.colors(of: style, frame: frame)
            let box = Box(
                x: metrics.paddingX + (column - 1) * metrics.cellWidth,
                y: metrics.originY + row * metrics.cellHeight,
                width: span * metrics.cellWidth
            )
            let color = frame.palette.resolve(style.underlineColor) ?? colors.foreground
            drawDecorations(underlined, box: box, surface: &surface, line: color, strike: colors.foreground)
            column += span - 1
        }
    }
}
