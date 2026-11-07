import Testing

@testable import SunsetCore

@Suite("Scroll accumulator") struct ScrollAccumulatorTests {
    @Test func `a trackpad moves one line per cell height of finger travel, times its sensitivity`() {
        var accumulator = ScrollAccumulator()
        #expect(accumulator.lines(delta: 37, precise: true, cellHeight: 18.5, trackpad: 1, wheel: 3) == 2)
        var fast = ScrollAccumulator()
        #expect(fast.lines(delta: 37, precise: true, cellHeight: 18.5, trackpad: 2.5, wheel: 3) == 5)
    }

    @Test func `the part of a line not yet scrolled is kept for the next event`() {
        var accumulator = ScrollAccumulator()
        var total = 0
        for _ in 0 ..< 10 { total += accumulator.lines(delta: 5, precise: true, cellHeight: 20, trackpad: 1, wheel: 3) }
        #expect(total == 2, "10 events of 5 points are 50 points: two lines of 20, 10 left over")
    }

    @Test func `a wheel notch is its delta times the wheel setting`() {
        var accumulator = ScrollAccumulator()
        #expect(accumulator.lines(delta: 1, precise: false, cellHeight: 18.5, trackpad: 1, wheel: 3) == 3)
        #expect(accumulator.lines(delta: -2, precise: false, cellHeight: 18.5, trackpad: 1, wheel: 3) == -6)
        #expect(accumulator.lines(delta: 1, precise: false, cellHeight: 18.5, trackpad: 1, wheel: 0.5) == 0)
        #expect(
            accumulator.lines(delta: 1, precise: false, cellHeight: 18.5, trackpad: 1, wheel: 0.5) == 1,
            "two half-lines make one"
        )
    }

    @Test func `the direction is kept: positive goes back into the history, negative toward the live screen`() {
        var accumulator = ScrollAccumulator()
        #expect(accumulator.lines(delta: 40, precise: true, cellHeight: 20, trackpad: 1, wheel: 3) == 2)
        #expect(accumulator.lines(delta: -40, precise: true, cellHeight: 20, trackpad: 1, wheel: 3) == -2)
    }

    @Test func `a zero cell height or a zero setting scrolls nothing and does not trap`() {
        var accumulator = ScrollAccumulator()
        #expect(accumulator.lines(delta: 40, precise: true, cellHeight: 0, trackpad: 1, wheel: 3) == 0)
        #expect(accumulator.lines(delta: 40, precise: true, cellHeight: 20, trackpad: 0, wheel: 3) == 0)
        #expect(accumulator.lines(delta: .infinity, precise: false, cellHeight: 20, trackpad: 1, wheel: 3) == 0)
    }

    @Test func `a change of direction drops what was left over in the other direction`() {
        var accumulator = ScrollAccumulator()
        _ = accumulator.lines(delta: 15, precise: true, cellHeight: 20, trackpad: 1, wheel: 3)
        #expect(accumulator.lines(delta: -10, precise: true, cellHeight: 20, trackpad: 1, wheel: 3) == 0)
        #expect(
            accumulator.lines(delta: -10, precise: true, cellHeight: 20, trackpad: 1, wheel: 3) == -1,
            "10 + 10 points against it, not 15 - 10 - 10"
        )
    }
}
