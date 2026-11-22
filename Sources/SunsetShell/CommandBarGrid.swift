/// The command bar's keylines (grid systems: what is read together starts on one line): the field's glyph and its rows'
/// glyphs on one vertical line, the typed text and the rows' titles on the next. In the sidebar that line is the sidebar's
/// tabs' own (their leading padding); in the large bar, the rows' inset and padding as they were.
package struct CommandBarGrid: Equatable, Sendable {
    /// From the bar's edge to every glyph's frame.
    package let glyphLeading: Double
    /// From the list's edge to its rows' fills.
    package let listInset: Double
    /// From a row's fill to its glyph.
    package let rowPadding: Double

    /// From the bar's edge to the field's glyph: the rows' glyphs' line.
    package var fieldPadding: Double {
        glyphLeading
    }

    /// `sidebarLeading`: the sidebar's tabs' leading padding, for the bar in the sidebar's field; nil for the large bar.
    package init(sidebarLeading: Double?) {
        let inset = sidebarLeading == nil ? Design.Space.s : Design.Space.xs
        let leading = sidebarLeading.map { max($0, inset + Design.Space.xs) } ?? inset + Design.Space.l
        listInset = inset
        glyphLeading = leading
        rowPadding = leading - inset
    }
}
