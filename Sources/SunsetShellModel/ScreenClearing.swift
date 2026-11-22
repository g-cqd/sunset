/// The screen cleared for the sun (an easter egg that "would minimize windows on screen ... and start the animation"),
/// and put back after: only what it cleared, never what was already minimized or hidden.
package final class ScreenClearing {
    private var cleared: [any ClearableOnScreen] = []

    package init() {}

    /// Clears what of `things` is on screen.
    package func clear(_ things: [any ClearableOnScreen]) {
        let shown = things.filter(\.isShown)
        shown.forEach { $0.clear() }
        cleared += shown
    }

    /// Brings back what it cleared, once.
    package func restore() {
        let back = cleared
        cleared = []
        back.forEach { $0.bringBack() }
    }
}
