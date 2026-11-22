import Testing

@testable import SunsetShell
@testable import SunsetShellModel

/// The two-finger swipe on the sidebar that changes Space. It snaps to the Space, slow at first, then snapping once
/// swiped far enough, one Space at a time, with a tap of the trackpad at the snap.
@Suite("The swipe between Spaces")
struct SpaceSwipeTests {
    private let width = 240.0

    @Test func `a gesture that starts up or down is the list's: it never changes Space`() {
        var swipe = SpaceSwipe()
        swipe.begin()
        #expect(swipe.move(dx: 1, dy: -6, width: width, ways: (.space, .space)) == .scroll)
        #expect(
            swipe.move(dx: 80, dy: 0, width: width, ways: (.space, .space)) == .scroll,
            "decided once, at its start"
        )
        #expect(swipe.offset == 0)
        #expect(swipe.end() == nil)
    }

    @Test func `sideways, the list starts slow under the fingers and snaps once enough was swiped`() {
        var swipe = SpaceSwipe()
        swipe.begin()
        // Fingers to the left (the content goes left): the next Space.
        #expect(swipe.move(dx: -10, dy: 1, width: width, ways: (.space, .space)) == .follow)
        #expect(swipe.offset < 0 && swipe.offset > -10, "slower than the fingers")
        let early = swipe.offset
        #expect(swipe.move(dx: -20, dy: 0, width: width, ways: (.space, .space)) == .follow)
        #expect(swipe.offset < early && swipe.offset > -30)
        var result = SpaceSwipe.Step.follow
        var travelled = 30.0
        while result == .follow, travelled < 400 {
            result = swipe.move(dx: -10, dy: 0, width: width, ways: (.space, .space))
            travelled += 10
        }
        #expect(result == .snap(1), "the next Space")
        #expect(travelled <= width * SpaceSwipe.threshold + 10 && travelled >= width * SpaceSwipe.threshold)
        #expect(swipe.offset < -30, "left where the fingers had it: the slide goes on from there")
    }

    @Test func `one Space a gesture: what is swiped after the snap, and the trackpad's momentum, change nothing`() {
        var swipe = SpaceSwipe()
        swipe.begin()
        var snaps = 0
        for _ in 0 ..< 200 where swipe.move(dx: -10, dy: 0, width: width, ways: (.space, .space)) == .snap(1) {
            snaps += 1
        }
        #expect(snaps == 1)
        #expect(swipe.move(dx: -500, dy: 0, width: width, ways: (.space, .space)) == .consumed)
        #expect(swipe.end() == nil)
        // A new gesture can change again.
        swipe.begin()
        var again = 0
        for _ in 0 ..< 200 where swipe.move(dx: 10, dy: 0, width: width, ways: (.space, .space)) == .snap(-1) {
            again += 1
        }
        #expect(again == 1)
    }

    @Test
    func `let go before enough was swiped, the list goes back; swiped back past the start, it goes the other way`() {
        var swipe = SpaceSwipe()
        swipe.begin()
        _ = swipe.move(dx: -40, dy: 0, width: width, ways: (.space, .space))
        #expect(swipe.offset < 0)
        #expect(swipe.end() == nil && swipe.offset == 0)
        swipe.begin()
        _ = swipe.move(dx: -40, dy: 0, width: width, ways: (.space, .space))
        _ = swipe.move(dx: 60, dy: 0, width: width, ways: (.space, .space))
        #expect(swipe.offset > 0, "towards the previous Space now")
    }

    /// The gesture is the list's, nothing moves.
    @Test func `towards a side with nothing the gesture is given back: nothing moves, nothing snaps`() {
        var swipe = SpaceSwipe()
        swipe.begin()
        var results: Set<String> = []
        for _ in 0 ..< 100 {
            results.insert("\(swipe.move(dx: -10, dy: 0, width: width, ways: (previous: .space, next: .nothing)))")
        }
        #expect(results == ["scroll"] && swipe.offset == 0)
    }

    /// "allow a swipe gesture that allows to open the library when reaching the furthest away space on the side the
    /// sidebar is": past that Space, the Library is there to swipe to, as a Space would be.
    @Test func `past the last Space on the sidebar's side, the Library: followed, then opened once`() {
        var swipe = SpaceSwipe()
        swipe.begin()
        var result = SpaceSwipe.Step.follow
        var count = 0
        while result == .follow, count < 200 {
            result = swipe.move(dx: 10, dy: 0, width: width, ways: (previous: .library, next: .space))
            count += 1
        }
        #expect(result == .library)
        #expect(swipe.move(dx: 10, dy: 0, width: width, ways: (previous: .library, next: .space)) == .consumed)
    }

    @Test func `what each side holds: a Space, else the Library on the sidebar's side, else nothing`() {
        #expect(SpaceSwipe.ways(index: 0, count: 3, library: .previous) == (.library, .space))
        #expect(SpaceSwipe.ways(index: 2, count: 3, library: .previous) == (.space, .nothing))
        #expect(SpaceSwipe.ways(index: 2, count: 3, library: .next) == (.space, .library))
        #expect(SpaceSwipe.ways(index: 0, count: 1, library: .previous) == (.library, .nothing))
        #expect(SpaceSwipe.ways(index: 0, count: 1, library: nil) == (.nothing, .nothing))
    }

    /// "we should not catch swipe gestures when in the settings or help with the sidebar filled by the settings
    /// sidebar": nor with any of the Library's lists in it, where the Spaces are not shown.
    @Test func `listened to only while the tabs show, and only if there is somewhere to go`() {
        #expect(SpaceSwipe.listens(libraryOpen: false, spaces: 2, library: nil))
        #expect(SpaceSwipe.listens(libraryOpen: false, spaces: 1, library: .previous))
        #expect(!SpaceSwipe.listens(libraryOpen: false, spaces: 1, library: nil))
        // With the Library open, listened to for the way back to the tabs, where the Library is offered by a swipe.
        #expect(SpaceSwipe.listens(libraryOpen: true, spaces: 3, library: .previous))
        #expect(!SpaceSwipe.listens(libraryOpen: true, spaces: 3, library: nil))
    }

    /// "swipe back into tabs when in the library … the opposite to the one that led into the library".
    @Test func `with the Library open, only the way back leads somewhere: opposite to the way in`() {
        #expect(SpaceSwipe.ways(index: 0, count: 3, library: .previous, libraryOpen: true) == (.nothing, .library))
        #expect(SpaceSwipe.ways(index: 2, count: 3, library: .next, libraryOpen: true) == (.library, .nothing))
        #expect(SpaceSwipe.ways(index: 1, count: 3, library: nil, libraryOpen: true) == (.nothing, .nothing))
    }
}
