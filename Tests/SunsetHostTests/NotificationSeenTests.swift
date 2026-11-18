import Testing

@testable import SunsetHost

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
