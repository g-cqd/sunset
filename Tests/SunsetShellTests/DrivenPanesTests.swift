import SunsetTestSupport
import Testing

@testable import SunsetShellModel

/// A pane driven from outside is marked a while; stopped, the tool is refused it.
@MainActor @Suite("Panes driven from outside")
struct DrivenPanesTests {
    private final class Pane {}

    @Test func `marked while driven, unmarked after the hold`() async throws {
        let time = TestTime()
        let panes = DrivenPanes()
        panes.runtime = time.runtime
        let pane = Pane()
        #expect(!panes.isDriven(pane))
        let mark = time.mark()
        #expect(panes.drive(pane))
        #expect(panes.isDriven(pane))
        try await time.release(after: .seconds(10), since: mark)
        #expect(!panes.isDriven(pane))
    }

    @Test func `stopped, the tool is refused that pane and no other`() {
        let panes = DrivenPanes()
        let (stopped, other) = (Pane(), Pane())
        #expect(panes.drive(stopped))
        panes.stop(stopped)
        #expect(!panes.isDriven(stopped))
        #expect(!panes.drive(stopped))
        #expect(panes.drive(other))
    }
}
