package import SunsetPane

/// The kinds of tab the command bar offers to make: besides a page under a new tab's empty field, and when what is typed
/// names one; all of them, a page among them, when it was opened to make a new tab.
package enum NewKindChoices {
    package enum Kind: Equatable, Sendable, CaseIterable {
        case terminal
        case page
        case document

        /// The words that find it.
        var words: [String] {
            switch self {
                case .terminal: ["new", "terminal", "tab", "shell", "console"]
                case .page: ["new", "web", "page", "site", "browser", "tab"]
                case .document: ["new", "document", "note", "markdown", "text"]
            }
        }

        func isOn(_ scopes: Scopes) -> Bool {
            switch self {
                case .terminal: scopes.terminal
                case .page: scopes.web
                case .document: scopes.documents
            }
        }
    }

    /// The kinds to offer in the search bar for `typed`: a terminal and a document (each on) under a new tab's empty field;
    /// else those every typed word (two letters at least) starts one of the words of. Never a page: typing makes one.
    package static func kinds(typed: String, forNewPage: Bool, scopes: Scopes) -> [Kind] {
        let on = Kind.allCases.filter { $0 != .page && $0.isOn(scopes) }
        return matching(on, typed: typed, unasked: forNewPage ? on : [])
    }

    /// The kinds a new tab can be (Shift-Cmd-T): all that are on unasked; else narrowed by what is typed.
    package static func newTab(typed: String, scopes: Scopes) -> [Kind] {
        let on = Kind.allCases.filter { $0.isOn(scopes) }
        return matching(on, typed: typed, unasked: on)
    }

    private static func matching(_ on: [Kind], typed: String, unasked: [Kind]) -> [Kind] {
        let words = typed.lowercased().split(whereSeparator: \.isWhitespace).map(String.init)
        guard !words.isEmpty else { return unasked }
        guard words.allSatisfy({ $0.count >= 2 }) else { return [] }
        return on.filter { kind in
            words.allSatisfy { word in kind.words.contains { $0.hasPrefix(word) } }
        }
    }
}
