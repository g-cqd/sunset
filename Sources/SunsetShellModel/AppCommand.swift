package import SunsetPane

/// A command of the app: what the menus show and the command bar finds, by one table (`AppCommand.table`), so that a
/// command has one title, one key and one set of words wherever it is offered.
package struct AppCommand: Identifiable, Equatable, Sendable {
    package enum ID: String, Sendable, CaseIterable {
        case newWindow, newTab, newTabOfKind, newPrivateWindow, newPrivateTab, newDocument, openFile
        case closeTab, closeOtherTabs, closeWindow, print, importFromBrowser
        case commandBar, zoomIn, zoomOut, actualSize, previousPrompt, nextPrompt
        case library, documents, history, downloads, passwords, settings, help
        case splitRight, splitDown, nextPane, previousPane, movePaneToTab, renameTab, togglePinned, toggleFavorite
        case nextTab, previousTab
        case newSpace, editSpace, deleteSpace, nextSpace, previousSpace
        case back, forward, reload, reloadWithoutCache, forceReload, toggleMute, stop, openAddress, toggleInspector

        /// The Library's section it shows, for those that show one.
        package var librarySection: SidebarSection? {
            switch self {
                case .documents: .documents
                case .history: .history
                case .downloads: .downloads
                case .passwords: .passwords
                default: nil
            }
        }
    }

    package let id: ID
    package let title: String
    /// An SF Symbol's name: its glyph in the command bar.
    package let symbol: String
    /// The menu it is in: told beside it in the command bar.
    package let menu: String
    /// The words that find it in the command bar, besides its title's.
    package let words: [String]
    package let key: KeyChord?
    /// The scope it belongs to: not offered while that scope is off. Nil: always.
    package let scope: Scopes.Scope?
    /// Offered in the command bar: not the command that opens it.
    package let inBar: Bool

    init(
        _ id: ID,
        _ title: String,
        _ symbol: String,
        _ menu: String,
        key: KeyChord? = nil,
        scope: Scopes.Scope? = nil,
        words: [String] = [],
        inBar: Bool = true
    ) {
        self.id = id
        self.title = title
        self.symbol = symbol
        self.menu = menu
        self.key = key
        self.scope = scope
        self.words = words
        self.inBar = inBar
    }

    /// The command named `id`.
    package static subscript(id: ID) -> Self {
        // The table lists every ID (`AppCommandTableTests`).
        table.first { $0.id == id } ?? Self(id, id.rawValue, "questionmark", "")
    }

    /// Every word that finds it: its title's and its own, lowercased.
    var allWords: [String] {
        let titleWords = title.lowercased()
            .split { !$0.isLetter && !$0.isNumber }
            .map(String.init)
        return titleWords + words
    }

    /// The commands of the scopes that are on that every typed word (two letters at least) starts one word of; none unasked.
    package static func matching(typed: String, scopes: Scopes) -> [Self] {
        let typedWords = typed.lowercased().split(whereSeparator: \.isWhitespace).map(String.init)
        guard !typedWords.isEmpty, typedWords.allSatisfy({ $0.count >= 2 }) else { return [] }
        return table.filter { command in
            guard command.inBar, command.scope.map({ scopes[$0] }) ?? true else { return false }
            let words = command.allWords
            return typedWords.allSatisfy { typed in words.contains { $0.hasPrefix(typed) } }
        }
    }
}
