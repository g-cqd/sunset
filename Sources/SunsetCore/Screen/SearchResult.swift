/// The outcome of running a `SearchQuery` against a `Screen` (T-3 / roadmap 0026): all matches in chronological
/// order (oldest scrollback line first), whether the match list hit its safety cap, and any regex compilation error.
public struct SearchResult: Sendable, Equatable {
    /// Hard cap on matches collected in one scan so pathological queries on huge scrollbacks stay bounded.
    public static let defaultLimit = 50_000

    public let matches: [SearchMatch]
    public let truncated: Bool
    public let error: String?

    public init(matches: [SearchMatch], truncated: Bool = false, error: String? = nil) {
        self.matches = matches
        self.truncated = truncated
        self.error = error
    }

    public static let empty = SearchResult(matches: [])
}
