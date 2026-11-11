import Foundation
import SunsetPane
import Testing

@Suite("Close confirmation") struct CloseConfirmationTests {
    @Test func `an idle tab closes immediately, while a busy tab arms on the first request and closes on the second`() {
        var guardState = CloseConfirmation()
        let idle = Workspace.ItemID()
        let busy = Workspace.ItemID()
        let start = ContinuousClock.now

        // Idle tab closes right away.
        var ok = guardState.shouldClose(.item(idle), isBusy: false, enabled: true, now: start)
        #expect(ok)
        #expect(!guardState.isArmed(item: idle, now: start))

        // Busy tab with confirmClose disabled closes right away.
        ok = guardState.shouldClose(.item(busy), isBusy: true, enabled: false, now: start)
        #expect(ok)

        // Busy tab with confirmClose enabled: first request arms it and refuses; second request within the window closes it.
        ok = guardState.shouldClose(.item(busy), isBusy: true, enabled: true, now: start)
        #expect(!ok)
        #expect(guardState.isArmed(item: busy, now: start + .seconds(1)))
        ok = guardState.shouldClose(.item(busy), isBusy: true, enabled: true, now: start + .seconds(1))
        #expect(ok)
        #expect(!guardState.isArmed(item: busy, now: start + .seconds(1)))
    }

    @Test func `the armed state expires after the timeout or when another tab is armed`() {
        var guardState = CloseConfirmation()
        let first = Workspace.ItemID()
        let second = Workspace.ItemID()
        let start = ContinuousClock.now

        var ok = guardState.shouldClose(.item(first), isBusy: true, enabled: true, now: start)
        #expect(!ok)
        #expect(!guardState.isArmed(item: first, now: start + .seconds(5)))
        // After expiry, a click arms again rather than closing.
        ok = guardState.shouldClose(.item(first), isBusy: true, enabled: true, now: start + .seconds(5))
        #expect(!ok)
        // Arming a second tab disarms the first.
        ok = guardState.shouldClose(.item(second), isBusy: true, enabled: true, now: start + .seconds(5))
        #expect(!ok)
        #expect(!guardState.isArmed(item: first, now: start + .seconds(5)))
        #expect(guardState.isArmed(item: second, now: start + .seconds(5)))
    }

    @Test func `confirming one pane does not confirm closing its whole tab, another pane of it, or the other tabs`() {
        var state = CloseConfirmation()
        let tab = Workspace.ItemID()
        let start = ContinuousClock.now
        var closes = state.shouldClose(.pane(PaneID(), in: tab), isBusy: true, enabled: true, now: start)
        #expect(!closes)
        #expect(state.isArmed(item: tab, now: start), "the tab of the pane is the one tinted")
        closes = state.shouldClose(.item(tab), isBusy: true, enabled: true, now: start)
        #expect(!closes, "a wider close asks again")
        closes = state.shouldClose(.pane(PaneID(), in: tab), isBusy: true, enabled: true, now: start)
        #expect(!closes, "so does another pane")
        closes = state.shouldClose(.others(tab), isBusy: true, enabled: true, now: start)
        #expect(!closes)
        #expect(!state.isArmed(item: tab, now: start) && state.isArmed(item: Workspace.ItemID(), now: start))
        closes = state.shouldClose(.others(tab), isBusy: true, enabled: true, now: start + .seconds(1))
        #expect(closes)
    }

    @Test func `an idle close of something else leaves what is armed armed`() {
        var state = CloseConfirmation()
        let busy = Workspace.ItemID()
        let start = ContinuousClock.now
        var closes = state.shouldClose(.item(busy), isBusy: true, enabled: true, now: start)
        #expect(!closes)
        closes = state.shouldClose(.item(Workspace.ItemID()), isBusy: false, enabled: true, now: start)
        #expect(closes)
        #expect(state.isArmed(item: busy, now: start))
    }
}
