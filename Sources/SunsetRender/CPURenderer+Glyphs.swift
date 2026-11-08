internal import SunsetCore

extension CPURenderer {
    /// The glyph table and the resolved styles, taken out of `self` for a frame (so that they are not shared, and copied on their first write); the table is
    /// started again if it is full. The caller puts them back (`putBack`).
    func takeWalk() -> Walk {
        var walk = Walk(glyphs: GlyphTable(generation: 0), styles: ResolvedStyles())
        swap(&walk.glyphs, &glyphTable)
        swap(&walk.styles, &resolvedStyles)
        if walk.glyphs.bitmaps.count >= glyphTableLimit {
            walk.glyphs.startAgain(generation: GlyphGenerations.next())
            runCache.removeAll()
            runCacheCount = 0
        }
        walk.styles.startFrame()
        return walk
    }

    /// Puts what `takeWalk` took back into the renderer.
    func putBack(_ walk: inout Walk) {
        swap(&walk.glyphs, &glyphTable)
        swap(&walk.styles, &resolvedStyles)
    }

    /// The cell's glyph number in `table`, 0 when it has none.
    func glyph(for cell: Cell, style: ResolvedStyle, wide: Bool, frame: Frame, table: inout GlyphTable) -> UInt32 {
        let (bold, italic) = (style.bold, style.italic)
        guard !cell.isCluster, cell.scalar < GlyphTable.directLimit else {
            return hashedGlyph(for: cell, bold: bold, italic: italic, wide: wide, frame: frame, table: &table)
        }
        let variant = GlyphTable.variant(bold: bold, italic: italic, wide: wide)
        let known = table.direct(cell.scalar, variant: variant)
        if known != GlyphTable.unknown { return known }
        let made = hashedGlyph(for: cell, bold: bold, italic: italic, wide: wide, frame: frame, table: &table)
        table.setDirect(cell.scalar, variant: variant, to: made)
        return made
    }

    private func hashedGlyph(
        for cell: Cell,
        bold: Bool,
        italic: Bool,
        wide: Bool,
        frame: Frame,
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
                    for: frame.screen.text(of: cell),
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
        lastPalette = frame.palette
        lastReverse = reverse
        lastBlink = textBlinkVisible
        lastScrolledBack = frame.scrolledBack
        lastSelection = frame.selection
        lastHoveredLink = frame.hoveredLink
        lastBackgroundAlpha = frame.backgroundAlpha
        lastSelectionRows = selectionRows
        lastSize = (frame.columns, frame.screen.rows)
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
