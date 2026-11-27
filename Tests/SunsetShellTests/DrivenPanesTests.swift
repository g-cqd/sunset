import SunsetTestSupport
import Testing

@testable import SunsetShellModel

/// A pane driven from outside is marked a while; stopped, the tool is refused it.
@MainActor @Suite("Panes driven from outside")
struct DrivenPanesTests {
    private final class Pane {}

    @Test func `marked while driven, unmarked after the hold`() async throws {
        let panes = DrivenPanes()
        panes.hold = .milliseconds(50)
        let pane = Pane()
        #expect(!panes.isDriven(pane))
        #expect(panes.drive(pane))
        #expect(panes.isDriven(pane))
        #expect(await RealWait.until { !panes.isDriven(pane) })
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
