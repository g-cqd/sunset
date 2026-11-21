import Testing

@testable import SunsetShellModel

/// The easter egg clears the screen for the sun and puts back only what it cleared.
@Suite("Clearing the screen for the sun")
struct ScreenClearingTests {
    final class Thing: ClearableOnScreen {
        var isShown: Bool
        var cleared = 0
        var broughtBack = 0
        init(shown: Bool) {
            isShown = shown
        }
        func clear() {
            cleared += 1
            isShown = false
        }
        func bringBack() {
            broughtBack += 1
            isShown = true
        }
    }

    @Test func `what is on screen is cleared, and brought back once; what was not is left alone`() {
        let shown = Thing(shown: true)
        let alreadyMinimized = Thing(shown: false)
        let clearing = ScreenClearing()
        clearing.clear([shown, alreadyMinimized])
        #expect(shown.cleared == 1 && !shown.isShown)
        #expect(alreadyMinimized.cleared == 0)
        clearing.restore()
        clearing.restore()
        #expect(shown.broughtBack == 1 && shown.isShown)
        #expect(alreadyMinimized.broughtBack == 0 && !alreadyMinimized.isShown)
    }
}
