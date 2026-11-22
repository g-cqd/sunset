package import SunsetPane

/// Commands of the menus the command bar also offers when what is typed names one (as a new kind of tab is): importing
/// another browser's things, and Sunset's own places: Settings, the Library and its lists, Help.
package enum AppCommandChoices {
    package enum Command: Equatable, Sendable, CaseIterable {
        case importFromBrowser
        case settings, library, documents, history, downloads, passwords, help

        /// The Library's section it shows, for those that show one.
        package var librarySection: SidebarSection? {
            switch self {
                case .documents: .documents
                case .history: .history
                case .downloads: .downloads
                case .passwords: .passwords
                case .importFromBrowser, .settings, .library, .help: nil
            }
        }

        /// The words that find it.
        var words: [String] {
            switch self {
                case .importFromBrowser:
                    ["import", "from", "another", "browser", "bookmarks", "chrome", "firefox", "safari", "extensions"]
                case .settings: ["settings", "preferences", "options", "configuration"]
                case .library: ["library", "sidebar"]
                case .documents: ["documents", "files", "notes"]
                case .history: ["history", "visited"]
                case .downloads: ["downloads"]
                case .passwords: ["passwords", "vault", "logins", "keys", "cards"]
                case .help: ["help", "manual", "documentation", "shortcuts"]
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
                case .documents: guard scopes.documents else { return false }
                case .history, .downloads: guard scopes.web else { return false }
                case .passwords: guard scopes.passwords else { return false }
                case .settings, .library, .help: break
            }
            return words.allSatisfy { word in command.words.contains { $0.hasPrefix(word) } }
        }
    }
}
