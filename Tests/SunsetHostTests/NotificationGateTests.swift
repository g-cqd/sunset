import Testing

@testable import SunsetHost

@Suite("Notification gate (ADR-0010)") struct NotificationGateTests {
    @Test func `a notification is shown while the window is not focused, at most one a second`() {
        var gate = NotificationGate()
        let shown = [0.0, 0.5, 0.999, 1.0].map { gate.admits(atSecond: $0, windowFocused: false) }
        #expect(shown == [true, false, false, true])
    }

    @Test func `none is shown while the window is focused, and those do not use up the allowance`() {
        var gate = NotificationGate()
        let focused = gate.admits(atSecond: 0, windowFocused: true)
        let later = gate.admits(atSecond: 0.1, windowFocused: false)
        #expect(!focused && later)
    }

    @Test func `a clock that goes backwards does not lock the gate`() {
        var gate = NotificationGate()
        let first = gate.admits(atSecond: 100, windowFocused: false)
        let second = gate.admits(atSecond: 5, windowFocused: false)
        #expect(first && second)
    }
}
