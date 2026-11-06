/// A press and drag of the pointer turned into a selection: by cells, by words (double click) or by lines (triple click), as text or as a block.
public struct SelectionGesture: Sendable, Equatable {
    public enum Granularity: Sendable, Equatable {
        case cells, words, lines
    }

    public let granularity: Granularity
    public let shape: Selection.Shape
    private let base: (start: SelectionPoint, end: SelectionPoint)

    public static func == (first: SelectionGesture, second: SelectionGesture) -> Bool {
        first.granularity == second.granularity && first.shape == second.shape && first.base == second.base
    }

    /// The pointer went down at `point`. A click by cells selects nothing until the pointer moves; a double or triple click selects the word or line.
    public init(at point: SelectionPoint, granularity: Granularity, shape: Selection.Shape = .linear, screen: Screen) {
        self.granularity = granularity
        self.shape = shape
        base = Self.range(at: point, granularity: granularity, screen: screen)
    }

    /// What is selected now, or nil when nothing is yet.
    public var selection: Selection? {
        guard granularity != .cells else { return nil }
        return Selection(anchor: base.start, head: base.end, shape: shape)
    }

    /// The pointer moved to `point`: the selection from where it went down to there, widened to whole words or lines.
    public func dragged(to point: SelectionPoint, screen: Screen) -> Selection? {
        let there = Self.range(at: point, granularity: granularity, screen: screen)
        if granularity == .cells, point == base.start { return nil }
        if there.start < base.start {
            return Selection(anchor: granularity == .cells ? base.start : base.end, head: there.start, shape: shape)
        }
        return Selection(anchor: base.start, head: there.end, shape: shape)
    }

    private static func range(at point: SelectionPoint, granularity: Granularity, screen: Screen) -> (
        start: SelectionPoint, end: SelectionPoint
    ) {
        switch granularity {
            case .cells: (point, point)
            case .words: screen.wordRange(at: point)
            case .lines: screen.lineRange(at: point.line)
        }
    }
}
