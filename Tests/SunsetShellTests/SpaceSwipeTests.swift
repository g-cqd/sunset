import Testing

@testable import SunsetShell

/// The two-finger swipe on the sidebar that changes Space (roadmap 0021 step S-b). The owner, 2026-11-17: "it should snap
/// to the space, starting slow and snap when enough swiped, not swipe multiple ones at the same time", with a tap of the
/// trackpad at the snap.
@Suite("The swipe between Spaces")
struct SpaceSwipeTests {
    private let width = 240.0

    @Test func `a gesture that starts up or down is the list's: it never changes Space`() {
        var swipe = SpaceSwipe()
        swipe.begin()
        #expect(swipe.move(dx: 1, dy: -6, width: width, canGo: (true, true)) == .scroll)
        #expect(swipe.move(dx: 80, dy: 0, width: width, canGo: (true, true)) == .scroll, "decided once, at its start")
        #expect(swipe.offset == 0)
        #expect(swipe.end() == nil)
    }

    @Test func `sideways, the list starts slow under the fingers and snaps once enough was swiped`() {
        var swipe = SpaceSwipe()
        swipe.begin()
        // Fingers to the left (the content goes left): the next Space.
        #expect(swipe.move(dx: -10, dy: 1, width: width, canGo: (true, true)) == .follow)
        #expect(swipe.offset < 0 && swipe.offset > -10, "slower than the fingers")
        let early = swipe.offset
        #expect(swipe.move(dx: -20, dy: 0, width: width, canGo: (true, true)) == .follow)
        #expect(swipe.offset < early && swipe.offset > -30)
        var result = SpaceSwipe.Step.follow
        var travelled = 30.0
        while result == .follow, travelled < 400 {
            result = swipe.move(dx: -10, dy: 0, width: width, canGo: (true, true))
            travelled += 10
        }
        #expect(result == .snap(1), "the next Space")
        #expect(travelled <= width * SpaceSwipe.threshold + 10 && travelled >= width * SpaceSwipe.threshold)
        #expect(swipe.offset == 0, "the list is the other Space's now")
    }

    @Test func `one Space a gesture: what is swiped after the snap, and the trackpad's momentum, change nothing`() {
        var swipe = SpaceSwipe()
        swipe.begin()
        var snaps = 0
        for _ in 0 ..< 200 where swipe.move(dx: -10, dy: 0, width: width, canGo: (true, true)) == .snap(1) {
            snaps += 1
        }
        #expect(snaps == 1)
        #expect(swipe.move(dx: -500, dy: 0, width: width, canGo: (true, true)) == .consumed)
        #expect(swipe.end() == nil)
        // A new gesture can change again.
        swipe.begin()
        var again = 0
        for _ in 0 ..< 200 where swipe.move(dx: 10, dy: 0, width: width, canGo: (true, true)) == .snap(-1) {
            again += 1
        }
        #expect(again == 1)
    }

    @Test
    func `let go before enough was swiped, the list goes back; swiped back past the start, it goes the other way`() {
        var swipe = SpaceSwipe()
        swipe.begin()
        _ = swipe.move(dx: -40, dy: 0, width: width, canGo: (true, true))
        #expect(swipe.offset < 0)
        #expect(swipe.end() == nil && swipe.offset == 0)
        swipe.begin()
        _ = swipe.move(dx: -40, dy: 0, width: width, canGo: (true, true))
        _ = swipe.move(dx: 60, dy: 0, width: width, canGo: (true, true))
        #expect(swipe.offset > 0, "towards the previous Space now")
    }

    @Test func `towards a side with no Space the list barely moves and never snaps`() {
        var swipe = SpaceSwipe()
        swipe.begin()
        var result = SpaceSwipe.Step.follow
        for _ in 0 ..< 100 { result = swipe.move(dx: -10, dy: 0, width: width, canGo: (previous: true, next: false)) }
        #expect(result == .follow && swipe.offset < 0 && swipe.offset > -width * 0.15)
    }
}
