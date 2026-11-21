package import SunsetPane

/// Commands of the menus the command bar also offers when what is typed names one (as a new kind of tab is): importing
/// another browser's things (roadmap 0111 G).
package enum AppCommandChoices {
    package enum Command: Equatable, Sendable, CaseIterable {
        case importFromBrowser

        /// The words that find it.
        var words: [String] {
            switch self {
                case .importFromBrowser:
                    ["import", "from", "another", "browser", "bookmarks", "chrome", "firefox", "safari", "extensions"]
            }
        }
    }

    /// The commands every typed word (two letters at least) starts one of the words of; none unasked.
    package static func commands(typed: String, scopes: Scopes) -> [Command] {
        let words = typed.lowercased().split(whereSeparator: \.isWhitespace).map(String.init)
        guard !words.isEmpty, words.allSatisfy({ $0.count >= 2 }) else { return [] }
        return Command.allCases.filter { command in
            switch command {
                case .importFromBrowser: guard scopes.web else { return false }
            }
            return words.allSatisfy { word in command.words.contains { $0.hasPrefix(word) } }
        }
    }
}
