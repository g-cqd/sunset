/// A headless terminal: bytes in, a screen out. The parser feeds the screen directly (the screen is its sink, in this module, so it is specialised).
public struct Terminal: Sendable {
    public private(set) var screen: Screen
    private var parser = VTParser()

    public init(
        columns: Int,
        rows: Int,
        scrollbackLimit: Int = 10_000,
        clusterLimit: Int = 1 << 20,
        palette: Palette = Palette()
    ) {
        screen = Screen(columns: columns, rows: rows, scrollbackLimit: scrollbackLimit, clusterLimit: clusterLimit)
        screen.palette = palette
    }

    /// Packs the old lines of the history (see `Screen.packHistory`).
    @discardableResult
    public mutating func packHistory(using codec: any HistoryCodec, keepingRecent: Int, limit: Int) -> Int {
        screen.packHistory(using: codec, keepingRecent: keepingRecent, limit: limit)
    }

    /// Marks every row clean: the renderer has taken what it needed (ADR-0024).
    public mutating func clearDirty() { screen.clearDirty() }

    /// The bytes the terminal wants sent back to the program (answers to queries), in order; the host writes them to the PTY.
    public mutating func takeReplies() -> [UInt8] { screen.takeReplies() }

    /// What the program asked the host to do (clipboard, notifications), in order; the host applies its policy (ADR-0010).
    public mutating func takeEvents() -> [HostEvent] { screen.takeEvents() }

    /// Changes the size of the screen. The primary screen is re-wrapped (lines that wrapped are joined and split again), the alternate one is cut or padded.
    public mutating func resize(columns: Int, rows: Int) { screen.resize(columns: columns, rows: rows) }

    public mutating func feed(_ bytes: Span<UInt8>) {
        parser.parse(bytes, into: &screen)
    }

    public mutating func feed(_ text: String) {
        var text = text
        text.withUTF8 { buffer in feed(buffer.span) }
    }
}

extension Terminal {
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
}
