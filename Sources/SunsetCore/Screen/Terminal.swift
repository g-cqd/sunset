/// A headless terminal: bytes in, a screen out. The parser feeds the screen directly (the screen is its sink, in this module, so it is specialised).
public struct Terminal: Sendable {
    public private(set) var screen: Screen
    private var parser = VTParser()

    public init(columns: Int, rows: Int) {
        screen = Screen(columns: columns, rows: rows)
    }

    public mutating func feed(_ bytes: Span<UInt8>) {
        parser.parse(bytes, into: &screen)
    }

    public mutating func feed(_ text: String) {
        var text = text
        text.withUTF8 { buffer in feed(buffer.span) }
    }
}
