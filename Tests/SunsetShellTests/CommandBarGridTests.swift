import Testing

@testable import SunsetShell

/// The command bar on one keyline (grid systems: what is read together starts on one line): the field's glyph and its
/// rows' glyphs on one vertical line, the typed text and the rows' titles on another, in the large bar and in the
/// sidebar's, where that line is the sidebar's tabs' own.
@Suite("The command bar's keylines")
struct CommandBarGridTests {
    @Test(arguments: [nil, 10.0, 14.0])
    func `the field's glyph and the rows' glyphs on one line; the text and the titles on another`(sidebar: Double?) {
        let grid = CommandBarGrid(sidebarLeading: sidebar)
        #expect(grid.listInset + grid.rowPadding == grid.glyphLeading)
        #expect(grid.fieldPadding == grid.glyphLeading)
        if let sidebar { #expect(grid.glyphLeading == sidebar, "the sidebar's tabs' line") }
        #expect(grid.rowPadding >= Design.Space.xs, "a row's fill keeps room around its glyph")
    }
}
