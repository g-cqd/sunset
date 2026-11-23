import CoreGraphics
import Foundation
import Testing

@testable import SunsetShellModel

/// A long press or a deep press opens the menu a right click would (the owner's note n112): held half a second without
/// moving more than a few points; a drag, a short click, or a press already ended does not.
@Suite("Long press opens the menu")
struct LongPressMenuTests {
    @Test func `held still half a second: the menu, once`() {
        var press = LongPress(at: CGPoint(x: 10, y: 10), time: .seconds(1))
        let early = press.isDue(at: .milliseconds(1_400))
        press.moved(to: CGPoint(x: 12, y: 13))
        let held = press.isDue(at: .milliseconds(1_500))
        let again = press.isDue(at: .milliseconds(1_600))
        #expect(!early)
        #expect(held, "a hand's tremble is still")
        #expect(!again, "once")
    }

    @Test func `a drag, a release or a deep press first: no long press`() {
        var dragged = LongPress(at: .zero, time: .zero)
        dragged.moved(to: CGPoint(x: 8, y: 0))
        let afterDrag = dragged.isDue(at: .seconds(2))
        var released = LongPress(at: .zero, time: .zero)
        released.end()
        let afterRelease = released.isDue(at: .seconds(2))
        var deep = LongPress(at: .zero, time: .zero)
        let first = deep.deepPressed()
        let second = deep.deepPressed()
        let afterDeep = deep.isDue(at: .seconds(2))
        #expect(!afterDrag && !afterRelease)
        #expect(first && !second && !afterDeep, "one menu a press")
    }
}
