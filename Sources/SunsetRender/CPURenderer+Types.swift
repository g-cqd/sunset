public import SunsetCore

/// What one frame of the CPU renderer is made of.
extension CPURenderer {
    /// What one frame draws with: the screen, the cursor, the default colours (swapped by reverse video) and the blink phase.
    ///
    /// A class, so that the walk shares it by reference: as a struct (720 bytes, most of it the `Screen`) it was copied into every `drawCell` call
    /// (measured with the disassembly: a 720-byte `memcpy` per cell). Its fields are constants, which need no exclusivity checks.
    final class Frame {
        let screen: Screen
        let cursor: CursorDrawn?
        let foreground: RGB
        let background: RGB
        let blinkVisible: Bool
        /// How many lines of history the window is scrolled back.
        let scrolledBack: Int
        let selection: Selection?
        /// The link under the pointer (an id from `Screen.linkID`), drawn underlined; 0 for none.
        let hoveredLink: UInt16
        /// How opaque the default background is (see `FrameView.backgroundAlpha`).
        let backgroundAlpha: UInt8
        /// What the walk reads on every cell, taken from the screen once: calling into `screen` copies it, 720 bytes, each time (measured).
        let styles: ContiguousArray<CellStyle>
        let palette: Palette
        let columns: Int
        /// The line (counted from the oldest of the history) the top row of the window shows.
        let firstLine: Int

        init(
            screen: Screen,
            cursor: CursorDrawn?,
            colors: (foreground: RGB, background: RGB),
            blinkVisible: Bool,
            view: FrameView,
            scrolledBack: Int
        ) {
            self.screen = screen
            self.cursor = cursor
            (foreground, background) = colors
            self.blinkVisible = blinkVisible
            self.scrolledBack = scrolledBack
            selection = view.selection
            hoveredLink = view.hoveredLink
            backgroundAlpha = view.backgroundAlpha
            styles = screen.cellStyles
            palette = screen.palette
            columns = screen.columns
            firstLine = screen.scrollbackCount - scrolledBack
        }

        func style(of cell: Cell) -> CellStyle { styles[Int(cell.styleID)] }

        /// The cells of a row of the window.
        func row(_ row: Int) -> RowCells { RowCells(cells: screen.viewportRow(row, scrolledBack: scrolledBack)) }

        func isSelected(row: Int, column: Int) -> Bool {
            selection?.contains(line: firstLine + row, column: column) ?? false
        }

        func isSelected(row: Int, column: Int, span: Int) -> Bool {
            guard selection != nil else { return false }
            for offset in 0 ..< span where isSelected(row: row, column: column + offset) { return true }
            return false
        }

        func cell(row: Int, column: Int) -> Cell {
            screen.viewportCell(row: row, column: column, scrolledBack: scrolledBack)
        }
    }

    /// What the walk of a frame writes as it goes, handed down `inout` (no dynamic exclusivity checks, as a class's properties would have): the glyph table
    /// and the frame's resolved styles. Taken out of the renderer for the frame, put back after.
    struct Walk {
        var glyphs: GlyphTable
        var styles: ResolvedStyles
    }

    /// A row's cells, read once for the row (`Screen.viewportRow`); past its end the cells are empty.
    struct RowCells {
        let cells: ArraySlice<Cell>

        subscript(column: Int) -> Cell {
            column < cells.count ? cells[cells.startIndex + column] : .empty
        }
    }

    /// Where a cell (or a double-width pair) is on the surface.
    struct Box {
        var x: Int
        var y: Int
        var width: Int
    }

    struct CursorDrawn: Equatable {
        var row: Int
        var column: Int
        var shape: CursorShape
    }

    /// A cell (or a double-width pair) to draw, and whether its glyph is drawn here (a run draws its glyphs itself).
    struct Placement {
        var row: Int
        var column: Int
        var span: Int
        var drawGlyph = true
    }
}
