/// A headless terminal: bytes in, a screen out. The parser feeds the screen directly (the screen is its sink, in this module, so it is specialised).
public struct Terminal: Sendable {
    public private(set) var screen: Screen
    private var parser = VTParser()

    public init(columns: Int, rows: Int, palette: Palette = Palette()) {
        screen = Screen(columns: columns, rows: rows)
        screen.palette = palette
    }

    /// Marks every row clean: the renderer has taken what it needed (ADR-0024).
    public mutating func clearDirty() { screen.clearDirty() }

    /// The bytes the terminal wants sent back to the program (answers to queries), in order; the host writes them to the PTY.
    public mutating func takeReplies() -> [UInt8] { screen.takeReplies() }

    public mutating func feed(_ bytes: Span<UInt8>) {
        parser.parse(bytes, into: &screen)
    }

    public mutating func feed(_ text: String) {
        var text = text
        text.withUTF8 { buffer in feed(buffer.span) }
    }
}
