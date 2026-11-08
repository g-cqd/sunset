internal import SunsetCore

extension CPURenderer {
    /// The glyph table, taken out of `self` for a frame (so that it is not shared, and copied on its first write); started again if it is full. The caller
    /// puts it back.
    func takeGlyphTable() -> GlyphTable {
        var table = GlyphTable(generation: 0)
        swap(&table, &glyphTable)
        if table.bitmaps.count >= glyphTableLimit {
            table.startAgain(generation: GlyphGenerations.next())
            runCache.removeAll()
            runCacheCount = 0
        }
        return table
    }

    /// The cell's glyph number in `table`, 0 when it has none.
    func glyph(for cell: Cell, style: CellStyle, wide: Bool, screen: Screen, table: inout GlyphTable) -> UInt32 {
        let bold = style.attributes.contains(.bold)
        let italic = style.attributes.contains(.italic)
        guard !cell.isCluster, cell.scalar < GlyphTable.directLimit else {
            return hashedGlyph(for: cell, bold: bold, italic: italic, wide: wide, screen: screen, table: &table)
        }
        let variant = GlyphTable.variant(bold: bold, italic: italic, wide: wide)
        let known = table.direct(cell.scalar, variant: variant)
        if known != GlyphTable.unknown { return known }
        let made = hashedGlyph(for: cell, bold: bold, italic: italic, wide: wide, screen: screen, table: &table)
        table.setDirect(cell.scalar, variant: variant, to: made)
        return made
    }

    private func hashedGlyph(
        for cell: Cell,
        bold: Bool,
        italic: Bool,
        wide: Bool,
        screen: Screen,
        table: inout GlyphTable
    ) -> UInt32 {
        let key = GlyphTable.Key(id: cell.scalar, cluster: cell.isCluster, bold: bold, italic: italic, wide: wide)
        if let cached = table[key] { return cached }
        // Lines, blocks and braille are drawn to the cell, not taken from the font.
        let made =
            !cell.isCluster
            ? BuiltInGlyphs.bitmap(for: cell.scalar, metrics: metrics, columns: wide ? 2 : 1)
            : nil
        let glyph = table.number(
            made
                ?? glyphs.glyph(
                    for: screen.text(of: cell),
                    bold: bold,
                    italic: italic,
                    columns: wide ? 2 : 1,
                    metrics: metrics
                )
        )
        table[key] = glyph
        return glyph
    }

    /// What this frame was drawn from, to tell what the next one has to draw again.
    func remember(
        _ frame: Frame,
        cursor: CursorDrawn?,
        reverse: Bool,
        textBlinkVisible: Bool,
        selectionRows: ClosedRange<Int>?
    ) {
        lastCursor = cursor
        lastPalette = frame.screen.palette
        lastReverse = reverse
        lastBlink = textBlinkVisible
        lastScrolledBack = frame.scrolledBack
        lastSelection = frame.selection
        lastHoveredLink = frame.hoveredLink
        lastBackgroundAlpha = frame.backgroundAlpha
        lastSelectionRows = selectionRows
        lastSize = (frame.screen.columns, frame.screen.rows)
    }

    /// Whether this frame has to draw everything again: the size, the palette, reverse video, the hovered link, the scroll position or the background alpha
    /// changed since the last one.
    func needsFullRedraw(_ screen: Screen, view: FrameView, reverse: Bool, scrolledBack: Int) -> Bool {
        let sizeChanged = lastSize.map { $0.columns != screen.columns || $0.rows != screen.rows } ?? true
        return sizeChanged || lastPalette != screen.palette || reverse != lastReverse
            || view.hoveredLink != lastHoveredLink || scrolledBack != lastScrolledBack
            || view.backgroundAlpha != lastBackgroundAlpha || (scrolledBack > 0 && screen.hasDirtyRows)
    }
}
