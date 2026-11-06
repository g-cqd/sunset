/// A glyph as coverage: one byte per pixel, 0 nothing and 255 fully covered, `width` x `height`, placed `left` pixels from the left of its cell and `top`
/// pixels from the top. A wide glyph is as wide as its two cells.
public final class GlyphBitmap: Sendable {
    public let width: Int
    public let height: Int
    public let left: Int
    public let top: Int
    public let coverage: [UInt8]

    public init(width: Int, height: Int, left: Int, top: Int, coverage: [UInt8]) {
        precondition(coverage.count == width * height, "one coverage byte per pixel")
        self.width = width
        self.height = height
        self.left = left
        self.top = top
        self.coverage = coverage
    }
}
