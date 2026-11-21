package import SunsetPane

/// The kinds of tab the command bar offers to make besides a page (the owner's note n71): under a new tab's empty field,
/// and when what is typed names one, so that a terminal or a document is made as a page is.
package enum NewKindChoices {
    package enum Kind: Equatable, Sendable, CaseIterable {
        case terminal
        case document

        /// The words that find it.
        var words: [String] {
            switch self {
                case .terminal: ["new", "terminal", "tab", "shell", "console"]
                case .document: ["new", "document", "note", "markdown", "text"]
            }
        }
    }

    /// The kinds to offer for `typed`: both (each on) under a new tab's empty field; else those every typed word (two
    /// letters at least) starts one of the words of.
    package static func kinds(typed: String, forNewPage: Bool, scopes: Scopes) -> [Kind] {
        let on = Kind.allCases.filter { kind in
            switch kind {
                case .terminal: scopes.terminal
                case .document: scopes.documents
            }
        }
        let words = typed.lowercased().split(whereSeparator: \.isWhitespace).map(String.init)
        guard !words.isEmpty else { return forNewPage ? on : [] }
        guard words.allSatisfy({ $0.count >= 2 }) else { return [] }
        return on.filter { kind in
            words.allSatisfy { word in kind.words.contains { $0.hasPrefix(word) } }
        }
    }
}
