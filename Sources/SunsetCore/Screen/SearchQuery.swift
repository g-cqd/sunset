/// Options for searching a terminal's scrollback and live screen (T-3 / roadmap 0026).
public struct SearchQuery: Sendable, Equatable {
    public var text: String
    public var isRegex: Bool
    public var matchCase: Bool

    public init(text: String, isRegex: Bool = false, matchCase: Bool = false) {
        self.text = text
        self.isRegex = isRegex
        self.matchCase = matchCase
    }
}
