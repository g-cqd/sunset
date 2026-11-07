internal import SunsetCore

extension CPURenderer {
    struct GlyphKey: Hashable {
        var id: UInt32
        var cluster: Bool
        var bold: Bool
        var italic: Bool
        var wide: Bool
    }

    func bitmap(for cell: Cell, style: CellStyle, wide: Bool, screen: Screen) -> GlyphBitmap? {
        let key = GlyphKey(
            id: cell.scalar,
            cluster: cell.isCluster,
            bold: style.attributes.contains(.bold),
            italic: style.attributes.contains(.italic),
            wide: wide
        )
        if let cached = cache[key] { return cached }
        // Lines, blocks and braille are drawn to the cell, not taken from the font.
        if !cell.isCluster, let own = BuiltInGlyphs.bitmap(for: cell.scalar, metrics: metrics, columns: wide ? 2 : 1) {
            cache[key] = .some(own)
            return own
        }
        let made = glyphs.glyph(
            for: screen.text(of: cell),
            bold: key.bold,
            italic: key.italic,
            columns: wide ? 2 : 1,
            metrics: metrics
        )
        cache[key] = .some(made)
        return made
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
