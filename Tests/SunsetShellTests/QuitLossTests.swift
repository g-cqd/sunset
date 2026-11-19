import Testing

@testable import SunsetShell
@testable import SunsetShellModel

@Suite("Whether quitting asks") struct QuitLossTests {
    let one = [QuitLoss(kind: .command, text: "make")]

    @Test func `edits to a file are asked about at every level, even never`() {
        let edits = [QuitLoss(kind: .document, text: "a.md has edits that are not saved.", file: "/tmp/a.md")]
        #expect(QuitLoss.asks(level: "never", losses: edits) && QuitLoss.asks(level: "never", losses: one + edits))
        #expect(!QuitLoss.asks(level: "never", losses: []))
    }

    @Test func `never never, always always, by default only when something would be lost`() {
        #expect(!QuitLoss.asks(level: "never", losses: one) && QuitLoss.asks(level: "always", losses: []))
        #expect(QuitLoss.asks(level: "whenLosing", losses: one) && !QuitLoss.asks(level: "whenLosing", losses: []))
    }
}
