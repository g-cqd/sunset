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

/// Roadmap 0045 B (the owner, 2026-11-18: "No notifications at all … even though some tabs might be emitting some"): a
/// program's notification was held back whenever Sunset was in front, from a tab nobody was looking at too.
@Suite("Who sees the pane that notifies (roadmap 0045 B)") struct NotificationSeenTests {
    @Test func `a pane is seen only shown, in the key window, of the app in front`() {
        #expect(NotificationGate.seen(appActive: true, windowKey: true, windowVisible: true, paneVisible: true))
        #expect(!NotificationGate.seen(appActive: true, windowKey: true, windowVisible: true, paneVisible: false))
        #expect(!NotificationGate.seen(appActive: true, windowKey: false, windowVisible: true, paneVisible: true))
        #expect(!NotificationGate.seen(appActive: true, windowKey: true, windowVisible: false, paneVisible: true))
        #expect(!NotificationGate.seen(appActive: false, windowKey: true, windowVisible: true, paneVisible: true))
    }

    @Test func `a tab in the background of the app in front notifies`() {
        var gate = NotificationGate()
        let seen = NotificationGate.seen(appActive: true, windowKey: true, windowVisible: true, paneVisible: false)
        let admitted = gate.admits(atSecond: 0, windowFocused: seen)
        #expect(admitted)
    }
}
