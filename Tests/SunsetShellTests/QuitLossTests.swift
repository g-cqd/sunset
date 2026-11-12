import Testing

@testable import SunsetShell

@Suite("Whether quitting asks") struct QuitLossTests {
    let one = [QuitLoss(kind: .command, text: "make")]

    @Test func `never never, always always, by default only when something would be lost`() {
        #expect(!QuitLoss.asks(level: "never", losses: one) && QuitLoss.asks(level: "always", losses: []))
        #expect(QuitLoss.asks(level: "whenLosing", losses: one) && !QuitLoss.asks(level: "whenLosing", losses: []))
    }
}
