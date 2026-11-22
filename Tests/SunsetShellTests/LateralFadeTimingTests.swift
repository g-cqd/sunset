import SwiftUI
import Testing

@testable import SunsetShell
@testable import SunsetShellModel

/// The sides' fade comes with the swipe and goes after it, animated, not in the frame the slide ends.
@MainActor @Suite("The sides' fade of a Space's swipe, in time")
struct LateralFadeTimingTests {
    @Test func `the fade is on from the first move and goes in an animation of its own after the slide`() {
        let window = TabsModel()
        window.slide.width = 240
        window.slide.duration = 0.25
        var animated: [() -> Void] = []
        window.runSlide = { _, change, completion in
            change()
            animated.append(change)
            completion()
        }
        #expect(!window.slide.masks)
        window.shift(spaceListTo: -30)
        #expect(window.slide.masks, "on from the first move")
        window.settleSpaceList()
        #expect(!window.slide.masks && animated.count == 2, "back at rest: gone, in its own animation")
    }
}
