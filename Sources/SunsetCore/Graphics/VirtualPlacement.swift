/// An image placed nowhere yet (`U=1`, kitty's Unicode placeholders; roadmap 0010 E): it is drawn wherever cells hold
/// `U+10EEEE` in the colour that names it, fitted into `columns` × `rows` cells, keeping its proportions, centred. Those
/// cells are text: they scroll, wrap and clear as text does, which a placement at the cursor does not.
public struct VirtualPlacement: Sendable, Equatable {
    public let image: UInt32
    /// The program's own number for it within its image; 0 when it gave none.
    public let placement: UInt32
    public let columns: Int
    public let rows: Int
    /// Above the text when 0 or more, below it when negative, as a placement's.
    public let layer: Int
}
