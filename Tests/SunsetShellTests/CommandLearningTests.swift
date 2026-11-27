import Testing

@testable import SunsetPane
@testable import SunsetShellModel

/// The command bar ranks the commands it finds and learns the one a query ran.
@Suite("The command bar's commands, ranked and learnt")
struct CommandLearningTests {
    private let all = Scopes(terminal: true, web: true, documents: true)

    @Test func `a command whose title has the words comes before one found by its other words`() {
        // "reload" is in Reload Page's title; Force Reload Page's and Without Cache's too, after it in the table.
        let found = AppCommand.matching(typed: "refresh", scopes: all).map(\.id)
        #expect(found == [.reload, .reloadWithoutCache, .forceReload])
        let byTitle = AppCommand.matching(typed: "zoom", scopes: all).map(\.id)
        #expect(byTitle.prefix(2) == [.zoomIn, .zoomOut] && byTitle.last == .actualSize)
    }

    @Test func `the more a command was run, the higher it comes; what a query ran last is learnt`() {
        var learning = CommandLearning()
        learning.ran(.forceReload, typed: "  Reload ")
        learning.ran(.forceReload, typed: "rel")
        let found = AppCommand.matching(typed: "reload", scopes: all, learning: learning).map(\.id)
        #expect(found.first == .forceReload)
        #expect(learning.command(for: "reload") == .forceReload)
        #expect(learning.command(for: "RELOAD") == .forceReload)
        #expect(learning.command(for: "reloa") == nil)
        learning.ran(.reload, typed: "reload")
        #expect(learning.command(for: "reload") == .reload)
    }

    @Test func `kept between launches as lines, read back the same; lines that are not its are left out`() {
        var learning = CommandLearning()
        learning.ran(.splitRight, typed: "split")
        learning.ran(.splitRight, typed: "sp r")
        let back = CommandLearning(saved: learning.saved + ["nonsense", "x\tnotACommand"])
        #expect(back == learning)
        #expect(back.uses(of: .splitRight) == 2)
    }

    @Test func `no more queries are kept than the limit, the oldest going first`() {
        var learning = CommandLearning()
        for index in 0 ... CommandLearning.limit { learning.ran(.newTab, typed: "q\(index)") }
        #expect(learning.command(for: "q0") == nil)
        #expect(learning.command(for: "q\(CommandLearning.limit)") == .newTab)
    }
}
