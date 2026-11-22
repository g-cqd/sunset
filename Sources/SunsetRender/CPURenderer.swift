public import SunsetCore

/// Draws a `Screen` into a `Surface` on the CPU: backgrounds, glyphs, decorations, the cursor. This is the reference renderer (the GPU one is held to its
/// output) and a product on its own. It redraws only what changed: the rows the screen marks dirty, the rows the cursor left and entered, and everything
/// when the palette, the size, reverse video or the blink phase changed. The caller clears the screen's dirty marks after a frame.
public final class CPURenderer: CellRenderer {
    public let metrics: RenderMetrics
    let glyphs: any GlyphSource
    /// Shape runs of cells together (ligatures and contextual alternates) when the glyph source can; a run never spans a cell with the cursor on it.
    public let ligatures: Bool
    var runCache: [UInt64: [RunEntry]] = [:]
    var runCacheCount = 0

    /// Every glyph made so far, by number. Taken out for the length of a frame (`render`) and handed down its walk. It starts again, under a new generation,
    /// at the first frame that finds it `glyphTableLimit` long or holding `glyphTableByteLimit` bytes: a run with a ligature is a bitmap as wide as the
    /// run, and text full of them would otherwise hold a hundred megabytes before the count was reached.
    var glyphTable = GlyphTable(generation: GlyphGenerations.next())
    var glyphTableLimit = 16_384
    var glyphTableByteLimit = 16 << 20
    /// The images made ready to draw, and those on the lines of the frame being drawn (`CPURenderer+Images`).
    var imageTable = ImageTable(generation: GlyphGenerations.next())
    var imageTableByteLimit = 128 << 20
    var shownImages: [ShownImage] = []
    /// What the cells of the row being drawn draw now (`CellPass`): all of themselves but on rows an image goes between.
    var cellPass = CellPass.all
    let imageDecoder: (any ImageDecoding)?
    var resolvedStyles = ResolvedStyles()
    var lastCursor: CursorDrawn?
    var lastPalette: Palette?
    var lastBackgroundAlpha: UInt8 = 255
    /// The surface's default background is translucent: text is blended with the kernel that handles a destination of any alpha.
    var translucent = false
    var lastReverse = false
    var lastBlink = true
    /// How many rows were drawn in all (a counter for tests and probes: a frame that changes nothing must draw nothing).
    var rowsDrawn = 0
    /// The pixel rows of the surface the last frame wrote to (the whole surface after a full redraw), nil when it wrote nothing: what a presenter has to upload.
    public internal(set) var changedPixelRows: ClosedRange<Int>?
    /// Which rows were drawn with blinking text: only those change when the blink phase does.
    var blinkRows: [Bool] = []
    var lastScrolledBack = 0
    var lastSelection: Selection?
    var lastHoveredLink: UInt16 = 0
    var lastSelectionRows: ClosedRange<Int>?
    var lastSize: (columns: Int, rows: Int)?
    var lastRecordedCount = 0

    public init(
        metrics: RenderMetrics,
        glyphs: any GlyphSource,
        ligatures: Bool = false,
        images: (any ImageDecoding)? = nil
    ) {
        self.metrics = metrics
        self.glyphs = glyphs
        imageDecoder = images
        self.ligatures = ligatures && glyphs.shapesRuns
    }

    /// How many glyph bitmaps the renderer holds and the bytes of their coverage: single characters, and the runs kept as one
    /// piece (for probes and tests: memory, the review of 2026-11-15).
    public var glyphStatistics: (count: Int, bytes: Int) {
        (glyphTable.bitmaps.count, glyphTable.bytes)
    }

    /// Forget what was drawn: the next frame draws everything (a new surface, a lost one).
    public func invalidate() {
        lastCursor = nil
        lastPalette = nil
        lastScrolledBack = 0
        lastSelection = nil
        lastHoveredLink = 0
        lastSelectionRows = nil
        lastSize = nil
        blinkRows = []
    }

    /// Draws the rows that need it. `cursorVisible` is the host's blink phase for the cursor (and the program's own show/hide is respected too);
    /// `textBlinkVisible` the phase of text with the blink attribute.
    public func render(
        _ screen: Screen,
        into surface: inout Surface,
        cursorVisible: Bool = true,
        textBlinkVisible: Bool = true,
        view: FrameView = FrameView()
    ) {
        var walk = takeWalk()
        defer { putBack(&walk) }
        let size = metrics.surfaceSize(columns: screen.columns, rows: screen.rows)
        precondition(
            surface.width >= size.width && surface.height >= size.height,
            "the surface is smaller than the grid"
        )
        let reverse = screen.modes.reverseVideo
        let scrolledBack = min(max(view.scrolledBack, 0), screen.scrollbackCount)
        let selection = view.selection
        let full = needsFullRedraw(screen, view: view, reverse: reverse, scrolledBack: scrolledBack)
        if blinkRows.count != screen.rows { blinkRows = [Bool](repeating: false, count: screen.rows) }
        let blinkChanged = textBlinkVisible != lastBlink
        let backgroundAlpha = view.backgroundAlpha
        translucent = backgroundAlpha < 255
        let background = Surface.pack(
            reverse ? screen.palette.foreground : screen.palette.background,
            alpha: backgroundAlpha
        )
        changedPixelRows = nil
        if full {
            fill(&surface, x: 0, y: 0, width: surface.width, height: surface.height, color: background)
            changedPixelRows = 0 ... surface.height - 1
        }

        let cursor = Self.cursor(of: screen, scrolledBack: scrolledBack, visible: cursorVisible)
        let cursorMoved = cursor != lastCursor
        let frame = Frame(
            screen: screen,
            cursor: cursor,
            colors: reverse
                ? (screen.palette.background, screen.palette.foreground)
                : (screen.palette.foreground, screen.palette.background),
            blinkVisible: textBlinkVisible,
            view: view,
            scrolledBack: scrolledBack
        )
        // The rows the selection covers now or covered in the last frame are drawn again when it changed.
        let selectionRows = selectionRows(of: selection, in: frame)
        let selectionChanged = selection != lastSelection
        prepareImages(screen, firstLine: frame.firstLine)
        let placed = full ? nil : moveScrolledRows(screen, frame: frame, surface: &surface)
        for row in 0 ..< screen.rows {
            let touchesCursor = cursorMoved && (cursor?.row == row || lastCursor?.row == row)
            let touchesSelection =
                selectionChanged
                && ((selectionRows?.contains(row) ?? false) || (lastSelectionRows?.contains(row) ?? false))
            let blinks = blinkChanged && blinkRows[row]
            let stale = screen.isDirty(row: row) && placed?[row] != true
            guard full || blinks || touchesCursor || touchesSelection || stale else { continue }
            drawRow(row, frame: frame, walk: &walk, surface: &surface)
        }
        remember(
            frame,
            cursor: cursor,
            reverse: reverse,
            textBlinkVisible: textBlinkVisible,
            selectionRows: selectionRows
        )
    }

    /// Works out what `render` would draw and returns it as a list of operations instead of drawing it: the surface (`width` x `height`) is not touched and
    /// need not exist. The renderer remembers the frame as drawn, as `render` does, so the caller must apply the list (a backend keeps the surface).
    public func record(
        _ screen: Screen,
        width: Int,
        height: Int,
        cursorVisible: Bool = true,
        textBlinkVisible: Bool = true,
        view: FrameView = FrameView()
    ) -> DrawFrame {
        var unbacked = Surface(unbackedWidth: width, height: height)
        // Room for as many operations as the last frame had: a list grown from empty is copied a dozen times in a full frame.
        unbacked.recorded.reserveCapacity(lastRecordedCount)
        render(screen, into: &unbacked, cursorVisible: cursorVisible, textBlinkVisible: textBlinkVisible, view: view)
        lastRecordedCount = unbacked.recorded.count
        return DrawFrame(
            width: width,
            height: height,
            ops: unbacked.recorded,
            move: unbacked.recordedMove,
            glyphs: glyphTable.bitmaps,
            glyphGeneration: glyphTable.generation,
            images: imageTable.images,
            imageGeneration: imageTable.generation,
            translucent: translucent,
            changedPixelRows: changedPixelRows
        )
    }
}
