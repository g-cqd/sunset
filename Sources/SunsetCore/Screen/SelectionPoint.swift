/// A place in the text of a terminal, counted in lines from the oldest line of the history (so it keeps pointing at the same text while new lines arrive
/// below) and columns from the left.
public struct SelectionPoint: Sendable, Equatable, Comparable {
    public var line: Int
    public var column: Int

    public init(line: Int, column: Int) {
        self.line = line
        self.column = column
    }

    public static func < (first: SelectionPoint, second: SelectionPoint) -> Bool {
        (first.line, first.column) < (second.line, second.column)
    }
}
