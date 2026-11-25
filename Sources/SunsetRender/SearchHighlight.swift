public import SunsetCore

/// Search highlights passed into a terminal frame for rendering (T-3 / roadmap 0026): the visible (or full) match list
/// and the index of the currently focused match. Drawn with a muted amber wash for passive matches and a bright gold
/// wash for the current match so both CPU and Metal renderers produce identical pixels.
public struct SearchHighlight: Sendable, Equatable {
    public var matches: [SearchMatch]
    public var current: Int?

    public init(matches: [SearchMatch] = [], current: Int? = nil) {
        self.matches = matches
        self.current = current
    }

    public var isEmpty: Bool {
        matches.isEmpty
    }

    /// The highlight state of the cell at (`line`, `column`) spanning `span` columns: `.current` wins over `.other`.
    public enum Kind: Sendable, Equatable {
        case none, other, current
    }

    public func kind(line: Int, column: Int, span: Int) -> Kind {
        guard !matches.isEmpty else { return .none }
        var foundOther = false
        for offset in 0 ..< span {
            let col = column + offset
            for (index, match) in matches.enumerated() where match.contains(line: line, column: col) {
                if index == current { return .current }
                foundOther = true
            }
        }
        return foundOther ? .other : .none
    }
}
