import Testing

@testable import SunsetCore

@Suite("Scroll momentum") struct ScrollMomentumTests {
    private func run(_ momentum: inout ScrollMomentum, frame: Double = 1.0 / 120, limit: Double = 5) -> [Int] {
        var steps: [Int] = []
        var time = 0.0
        while momentum.isMoving, time < limit {
            steps.append(momentum.advance(by: frame))
            time += frame
        }
        return steps
    }

    @Test func `an impulse is spread over time and covers the distance it was given`() {
        var momentum = ScrollMomentum(timeConstant: 0.2)
        momentum.push(lines: 30)
        let steps = run(&momentum)
        #expect(steps.count > 20, "it takes several frames, not one")
        let half = steps.count / 2
        #expect(steps[..<half].reduce(0, +) > steps[half...].reduce(0, +), "front-loaded: it decelerates")
        #expect((29 ... 30).contains(steps.reduce(0, +)), "total \(steps.reduce(0, +)) of 30 lines")
    }

    @Test func `a notch scrolls exactly the lines it asked for, however small: the last fraction is not lost at rest`()
    {
        for lines in [1.0, 2.0, 3.0, 6.0, -3.0, 0.5] {
            var momentum = ScrollMomentum(timeConstant: 0.2)
            momentum.push(lines: lines)
            let total = run(&momentum).reduce(0, +)
            #expect(total == Int(lines.rounded(.toNearestOrAwayFromZero)), "\(lines) lines gave \(total)")
        }
    }

    @Test func `the speed decays: each tenth of a second scrolls no more than the one before`() {
        var momentum = ScrollMomentum(timeConstant: 0.3)
        momentum.push(lines: 60)
        let steps = run(&momentum)
        // Single frames wobble (whole lines: 1, 0, 1), so compare 12-frame windows (0.1 s at 120 Hz).
        let windows = stride(from: 0, to: steps.count, by: 12)
            .map { steps[$0 ..< min($0 + 12, steps.count)].reduce(0, +) }
        #expect(windows.count > 3)
        #expect(
            zip(windows, windows.dropFirst()).allSatisfy { $0 + 1 >= $1 },
            "\(windows): within one line of whole-line rounding"
        )
    }

    @Test func `the distance does not depend on the frame rate`() {
        var slow = ScrollMomentum(timeConstant: 0.2)
        slow.push(lines: 40)
        var fast = ScrollMomentum(timeConstant: 0.2)
        fast.push(lines: 40)
        let slowTotal = run(&slow, frame: 1.0 / 30).reduce(0, +)
        let fastTotal = run(&fast, frame: 1.0 / 144).reduce(0, +)
        #expect(abs(slowTotal - fastTotal) <= 1, "\(slowTotal) at 30 Hz, \(fastTotal) at 144 Hz")
    }

    @Test func `a second notch while moving adds speed`() {
        var one = ScrollMomentum(timeConstant: 0.2)
        one.push(lines: 3)
        var two = ScrollMomentum(timeConstant: 0.2)
        two.push(lines: 3)
        _ = two.advance(by: 0.02)
        two.push(lines: 3)
        let single = run(&one).reduce(0, +)
        let double = run(&two).reduce(0, +)
        #expect(double > single + 2, "\(double) lines for two notches, \(single) for one")
    }

    @Test func `the other direction turns it round and a stop ends it`() {
        var momentum = ScrollMomentum(timeConstant: 0.2)
        momentum.push(lines: 30)
        momentum.push(lines: -30)
        #expect(run(&momentum).reduce(0, +).magnitude <= 1, "the two cancel")
        momentum.push(lines: 30)
        momentum.stop()
        #expect(!momentum.isMoving)
        #expect(momentum.advance(by: 0.1) == 0)
    }

    @Test func `no time constant means no momentum`() {
        var momentum = ScrollMomentum(timeConstant: 0)
        momentum.push(lines: 9)
        #expect(!momentum.isMoving)
        #expect(momentum.take() == 9, "the notch is scrolled at once")
    }
}
