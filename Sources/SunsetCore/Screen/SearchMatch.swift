/// A single search hit in a terminal's scrollback or live screen (T-3 / roadmap 0026): inclusive start and end
/// coordinates in absolute line numbers (0 = oldest scrollback line) so a match can span wrapped physical rows and
/// stay valid across rendering.
public struct SearchMatch: Sendable, Equatable {
    public let start: SelectionPoint
    public let end: SelectionPoint

    public init(start: SelectionPoint, end: SelectionPoint) {
        self.start = start
        self.end = end
    }

    /// Whether the cell at (`line`, `column`) falls inside this match (both ends inclusive).
    public func contains(line: Int, column: Int) -> Bool {
        guard line >= start.line, line <= end.line else { return false }
        if line == start.line, column < start.column { return false }
        if line == end.line, column > end.column { return false }
        return true
    }

    /// Converts this match to a linear `Selection` for copying or selection handoff.
    public var selection: Selection {
        Selection(anchor: start, head: end, shape: .linear)
    }
}
