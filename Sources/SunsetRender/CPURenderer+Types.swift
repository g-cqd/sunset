public import SunsetCore

/// What one frame of the CPU renderer is made of.
extension CPURenderer {
    /// What one frame draws with: the screen, the cursor, the default colours (swapped by reverse video) and the blink phase.
    struct Frame {
        var screen: Screen
        var cursor: CursorDrawn?
        var foreground: RGB
        var background: RGB
        var blinkVisible: Bool
        /// How many lines of history the window is scrolled back.
        var scrolledBack = 0
        var selection: Selection?

        /// The line (counted from the oldest of the history) the top row of the window shows.
        var firstLine: Int { screen.scrollbackCount - scrolledBack }

        func isSelected(row: Int, column: Int) -> Bool {
            selection?.contains(line: firstLine + row, column: column) ?? false
        }

        func isSelected(row: Int, column: Int, span: Int) -> Bool {
            (0 ..< span).contains { isSelected(row: row, column: column + $0) }
        }

        func cell(row: Int, column: Int) -> Cell {
            screen.viewportCell(row: row, column: column, scrolledBack: scrolledBack)
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
