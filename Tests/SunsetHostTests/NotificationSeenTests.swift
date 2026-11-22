import Testing

@testable import SunsetHost

/// A program's notification is held back only when its pane is seen: Sunset in front used to hold back every one, from a
/// tab nobody was looking at too, so none was ever shown.
@Suite("Who sees the pane that notifies") struct NotificationSeenTests {
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
