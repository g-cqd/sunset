import SunsetTestSupport
import Testing

@testable import SunsetRenderMac

/// When a terminal's renderer is told to rest: once no frame has been drawn for a while, and once only. On the test's clock:
/// every step of the time is the test's.
@MainActor @Suite("Resting after the last frame") struct FrameRestTests {
    final class Counter {
        var rests = 0
    }

    private let time = TestTime()

    @Test func `the renderer rests once, a while after the last frame, not while frames come`() async throws {
        let counter = Counter()
        let rest = FrameRest(after: .milliseconds(150), runtime: time.runtime)
        let drawn = {
            rest.frameDrawn {
                counter.rests += 1
                return true
            }
        }
        let first = time.mark()
        drawn()
        try await time.waited(since: first)
        // A frame every 100 ms: each wait wakes before the delay since the last frame is over, and waits for what is left.
        for _ in 0 ..< 5 {
            time.advance(.milliseconds(50))
            drawn()
            try await time.passStillWaiting(.milliseconds(100))
        }
        #expect(counter.rests == 0, "frames were still coming")
        try await time.pass(.milliseconds(400))
        #expect(counter.rests == 1)
        try await time.pass(.milliseconds(300))
        #expect(counter.rests == 1, "once, until a frame is drawn again")
        let again = time.mark()
        drawn()
        try await time.release(after: .milliseconds(150), since: again)
        #expect(counter.rests == 2)
    }

    @Test func `a terminal that stops is not told to rest`() async throws {
        let counter = Counter()
        let rest = FrameRest(after: .milliseconds(100), runtime: time.runtime)
        rest.frameDrawn {
            counter.rests += 1
            return true
        }
        rest.cancel()
        try await time.pass(.milliseconds(300))
        #expect(counter.rests == 0)
    }

    @Test func `a renderer that could not let everything go is asked again, a few times and no more`() async throws {
        let counter = Counter()
        let rest = FrameRest(after: .milliseconds(60), runtime: time.runtime)
        let first = time.mark()
        rest.frameDrawn {
            counter.rests += 1
            return counter.rests == 3
        }
        try await time.waited(since: first)
        // Asked, not done: it waits again; the third time it has let go, and nothing waits after.
        try await time.passStillWaiting(.milliseconds(60))
        try await time.passStillWaiting(.milliseconds(60))
        try await time.pass(.milliseconds(60))
        #expect(counter.rests == 3, "until it had let go")

        let never = Counter()
        let stubborn = FrameRest(after: .milliseconds(40), runtime: time.runtime)
        let started = time.mark()
        stubborn.frameDrawn {
            never.rests += 1
            return false
        }
        try await time.waited(since: started)
        for _ in 1 ..< FrameRest.tries {
            try await time.passStillWaiting(.milliseconds(40))
        }
        try await time.pass(.milliseconds(40))
        #expect(never.rests == FrameRest.tries)
    }
}
