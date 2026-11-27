import Testing

@testable import SunsetPane
@testable import SunsetShellModel

/// The command bar offers Import from Another Browser when it is asked for.
@Suite("Menu commands in the command bar")
struct AppCommandTableTests {
    private let all = Scopes(terminal: true, web: true, documents: true)

    private func ids(_ typed: String, _ scopes: Scopes) -> [AppCommand.ID] {
        AppCommand.matching(typed: typed, scopes: scopes).map(\.id)
    }

    @Test func `the table lists every command once, each key once`() {
        #expect(
            AppCommand.table.map(\.id).sorted { $0.rawValue < $1.rawValue }
                == AppCommand.ID.allCases.sorted { $0.rawValue < $1.rawValue }
        )
        let keys = AppCommand.table.compactMap(\.key)
        #expect(Set(keys).count == keys.count)
    }

    @Test func `the menus' commands are found by their title's words, with their key`() {
        #expect(ids("split right", all) == [.splitRight])
        #expect(AppCommand[.splitDown].key?.symbols == "\u{21E7}\u{2318}D")
        #expect(ids("prompt", Scopes(terminal: false, web: true, documents: true)).isEmpty)
        #expect(!ids("command bar", all).contains(.commandBar))
    }

    @Test func `found by its words, two letters at least each; none unasked`() {
        #expect(ids("import", all) == [.importFromBrowser])
        #expect(ids("imp bookm", all) == [.importFromBrowser])
        #expect(ids("Firefox", all) == [.importFromBrowser])
        #expect(ids("", all).isEmpty)
        #expect(ids("i", all).isEmpty)
        #expect(ids("import cats", all).isEmpty)
    }

    /// "the command bar should include more internal commands like settings, documents, history, library, help".
    @Test func `Sunset's own places are commands: settings, the Library's lists, help`() {
        #expect(ids("settings", all) == [.settings])
        #expect(ids("prefer", all) == [.settings])
        #expect(ids("history", all) == [.history])
        #expect(ids("documents", all) == [.documents])
        #expect(ids("library", all) == [.library])
        #expect(ids("help", all) == [.help])
        #expect(ids("downloads", all) == [.downloads])
        let noWeb = Scopes(terminal: true, web: false, documents: false)
        #expect(ids("history", noWeb).isEmpty)
        #expect(ids("documents", noWeb).isEmpty)
        #expect(ids("settings", noWeb) == [.settings])
    }

    @Test func `not offered with the web off`() {
        #expect(ids("import", Scopes(terminal: true, web: false, documents: true)).isEmpty)
    }
}
