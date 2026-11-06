/// What the user selected: from where they pressed to where they are (or let go), as text running through the lines, or as a block of columns.
public struct Selection: Sendable, Equatable {
    public enum Shape: Sendable, Equatable {
        case linear, block
    }

    public var anchor: SelectionPoint
    public var head: SelectionPoint
    public var shape: Shape

    public init(anchor: SelectionPoint, head: SelectionPoint, shape: Shape = .linear) {
        self.anchor = anchor
        self.head = head
        self.shape = shape
    }

    /// The earlier and the later end, whichever way it was dragged.
    public var start: SelectionPoint { min(anchor, head) }
    public var end: SelectionPoint { max(anchor, head) }

    /// Whether the cell at (`line`, `column`) is inside the selection (both ends included).
    public func contains(line: Int, column: Int) -> Bool {
        let first = start
        let last = end
        guard line >= first.line, line <= last.line else { return false }
        switch shape {
            case .block:
                return column >= min(anchor.column, head.column) && column <= max(anchor.column, head.column)
            case .linear:
                if line == first.line, column < first.column { return false }
                if line == last.line, column > last.column { return false }
                return true
        }
    }
}
