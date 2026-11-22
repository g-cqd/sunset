import Testing

@testable import SunsetPane
@testable import SunsetShellModel

/// The command bar offers Import from Another Browser when it is asked for.
@Suite("Menu commands in the command bar")
struct AppCommandChoicesTests {
    private let all = Scopes(terminal: true, web: true, documents: true)

    @Test func `found by its words, two letters at least each; none unasked`() {
        #expect(AppCommandChoices.commands(typed: "import", scopes: all) == [.importFromBrowser])
        #expect(AppCommandChoices.commands(typed: "imp bookm", scopes: all) == [.importFromBrowser])
        #expect(AppCommandChoices.commands(typed: "Firefox", scopes: all) == [.importFromBrowser])
        #expect(AppCommandChoices.commands(typed: "", scopes: all).isEmpty)
        #expect(AppCommandChoices.commands(typed: "i", scopes: all).isEmpty)
        #expect(AppCommandChoices.commands(typed: "import cats", scopes: all).isEmpty)
    }

    /// "the command bar should include more internal commands like settings, documents, history, library, help".
    @Test func `Sunset's own places are commands: settings, the Library's lists, help`() {
        #expect(AppCommandChoices.commands(typed: "settings", scopes: all) == [.settings])
        #expect(AppCommandChoices.commands(typed: "prefer", scopes: all) == [.settings])
        #expect(AppCommandChoices.commands(typed: "history", scopes: all) == [.history])
        #expect(AppCommandChoices.commands(typed: "documents", scopes: all) == [.documents])
        #expect(AppCommandChoices.commands(typed: "library", scopes: all) == [.library])
        #expect(AppCommandChoices.commands(typed: "help", scopes: all) == [.help])
        #expect(AppCommandChoices.commands(typed: "downloads", scopes: all) == [.downloads])
        let noWeb = Scopes(terminal: true, web: false, documents: false)
        #expect(AppCommandChoices.commands(typed: "history", scopes: noWeb).isEmpty)
        #expect(AppCommandChoices.commands(typed: "documents", scopes: noWeb).isEmpty)
        #expect(AppCommandChoices.commands(typed: "settings", scopes: noWeb) == [.settings])
    }

    @Test func `not offered with the web off`() {
        #expect(
            AppCommandChoices.commands(typed: "import", scopes: Scopes(terminal: true, web: false, documents: true))
                .isEmpty
        )
    }
}
