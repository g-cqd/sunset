/// An image shown on the screen (ADR-0117): over `columns` × `rows` cells from `column` of the line `stableLine` (a stable
/// line number, as `PromptMark`'s: it moves with the text as the screen scrolls, and goes when its line leaves the
/// history).
public struct ImagePlacement: Sendable, Equatable {
    public let image: UInt32
    /// The program's own number for it within its image; 0 when it gave none.
    public let placement: UInt32
    public let stableLine: Int
    public let column: Int
    public let columns: Int
    public let rows: Int
    /// The size it is drawn at, in pixels: the image's own, or as the program asked (`c`, `r`: stretched over those cells,
    /// or, with one of them, scaled keeping its proportions). Drawn from the top left of its cells, clipped to them.
    public let width: Int
    public let height: Int
    /// Above the text when 0 or more, below it when negative.
    public let layer: Int
}
