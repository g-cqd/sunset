/// What a run of cells looks like (everything but the character). Cells hold a 16-bit id into the screen's style table, not this value.
public struct CellStyle: Sendable, Hashable {
    public var foreground = Color.default
    public var background = Color.default
    public var underlineColor = Color.default
    public var attributes: Attributes = []
    public var underline = UnderlineStyle.none

    public init() {}
}
