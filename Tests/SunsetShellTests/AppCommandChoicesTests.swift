import Testing

@testable import SunsetPane
@testable import SunsetShellModel

/// The command bar offers Import from Another Browser when it is asked for (roadmap 0111 G).
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

    @Test func `not offered with the web off`() {
        #expect(
            AppCommandChoices.commands(typed: "import", scopes: Scopes(terminal: true, web: false, documents: true))
                .isEmpty
        )
    }
}
