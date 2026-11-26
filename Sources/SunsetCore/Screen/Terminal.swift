/// A headless terminal: bytes in, a screen out. The parser feeds the screen directly (the screen is its sink, in this module, so it is specialised).
public struct Terminal: Sendable {
    public private(set) var screen: Screen
    private var parser: VTParser

    public init(
        columns: Int,
        rows: Int,
        scrollbackLimit: Int = 10_000,
        clusterLimit: Int = 1 << 20,
        palette: Palette = Palette(),
        acceptsC1: Bool = false
    ) {
        // An inline image (Sixel DCS or iTerm2 OSC 1337 File=) can exceed 1 MiB; allow up to 16 MiB while
        // Screen+OSC / Screen+Graphics / Screen+GraphicsInline enforce per-protocol caps.
        parser = VTParser(maxStringLength: 16 << 20, acceptsC1: acceptsC1)
        screen = Screen(columns: columns, rows: rows, scrollbackLimit: scrollbackLimit, clusterLimit: clusterLimit)
        screen.palette = palette
    }

    /// Packs the old lines of the history (see `Screen.packHistory`).
    @discardableResult
    public mutating func packHistory(using codec: any HistoryCodec, keepingRecent: Int, limit: Int) -> Int {
        screen.packHistory(using: codec, keepingRecent: keepingRecent, limit: limit)
    }

    /// Marks every row clean: the renderer has taken what it needed.
    public mutating func clearDirty() {
        screen.clearDirty()
    }

    /// The bytes the terminal wants sent back to the program (answers to queries), in order; the host writes them to the PTY.
    public mutating func takeReplies() -> [UInt8] {
        screen.takeReplies()
    }

    /// What the program asked the host to do (clipboard, notifications), in order; the host applies its policy.
    public mutating func takeEvents() -> [HostEvent] {
        screen.takeEvents()
    }

    /// Changes the size of the screen. The primary screen is re-wrapped (lines that wrapped are joined and split again), the alternate one is cut or padded.
    public mutating func resize(columns: Int, rows: Int) {
        screen.resize(columns: columns, rows: rows)
    }

    public mutating func feed(_ bytes: Span<UInt8>) {
        parser.parse(bytes, into: &screen)
    }

    public mutating func feed(_ text: String) {
        var text = text
        text.withUTF8 { buffer in feed(buffer.span) }
    }
}

extension Terminal {
    /// Sets the cursor style the host wants: it is the cursor now unless a program chose one, and what DECSCUSR 0 and the resets go back to.
    public mutating func setDefaultCursor(shape: CursorShape, blinks: Bool) {
        screen.defaultCursor = (shape, blinks)
        if !screen.cursorChosen { (screen.cursorShape, screen.cursorBlinks) = (shape, blinks) }
    }

    /// Sets the 16 ANSI colours from the host's theme (see `Palette.setAnsi`); the rest of the palette is not touched. The whole screen is drawn again.
    public mutating func setAnsiColors(_ colors: [RGB]) {
        screen.palette.setAnsi(colors)
        screen.markDirty(0 ... screen.rows - 1)
    }

    /// Sets the default foreground, background and cursor colours from the host's theme (nil leaves one as it is). A program's reset of them (OSC 110-112)
    /// goes back to these. The palette's 256 entries are not touched. The whole screen is drawn again.
    public mutating func setDefaultColors(foreground: RGB?, background: RGB?, cursor: RGB?) {
        screen.palette.setDefaults(foreground: foreground, background: background, cursor: cursor)
        screen.markDirty(0 ... screen.rows - 1)
    }

    /// Moves running Kitty animations on (roadmap 0010 E): `now` is the host's monotonic time in milliseconds; the
    /// result says whether to draw and when to call again (`Screen.advanceAnimations`).
    public mutating func advanceAnimations(nowMilliseconds now: Int64) -> Screen.AnimationTick {
        screen.advanceAnimations(nowMilliseconds: now)
    }

    /// A cell's size in pixels, as the host draws it: an image takes as many cells as its pixels cover (ADR-0117).
    public mutating func setCellPixelSize(width: Int, height: Int) {
        let nextWidth = max(width, 1)
        let nextHeight = max(height, 1)
        guard nextWidth != screen.graphics.cellWidth || nextHeight != screen.graphics.cellHeight else { return }
        screen.graphics.cellWidth = nextWidth
        screen.graphics.cellHeight = nextHeight
        if !screen.graphics.placements.isEmpty || !screen.graphics.virtualPlacements.isEmpty {
            screen.markDirty(0 ... screen.rows - 1)
        }
    }

    /// The most a terminal's images may take, in bytes (64 MiB unless said).
    public mutating func setGraphicsQuota(bytes: Int) {
        screen.graphics.quota = max(bytes, 0)
    }

    /// What reads compressed images (`o=z`); until it is given, they are refused.
    public mutating func setInflater(_ inflater: any Inflater) {
        screen.graphics.inflater = inflater
    }
}
