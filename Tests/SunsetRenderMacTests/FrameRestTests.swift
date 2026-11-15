import Testing

@testable import SunsetRenderMac

/// When a terminal's renderer is told to rest: once no frame has been drawn for a while, and once only.
@MainActor @Suite("Resting after the last frame") struct FrameRestTests {
    final class Counter {
        var rests = 0
    }

    func waited(_ duration: Duration) async { try? await Task.sleep(for: duration) }

    @Test func `the renderer rests once, a while after the last frame, not while frames come`() async {
        let counter = Counter()
        let rest = FrameRest(after: .milliseconds(150))
        for _ in 0 ..< 6 {
            rest.frameDrawn {
                counter.rests += 1
                return true
            }
            await waited(.milliseconds(50))
        }
        #expect(counter.rests == 0, "frames were still coming")
        await waited(.milliseconds(400))
        #expect(counter.rests == 1)
        await waited(.milliseconds(300))
        #expect(counter.rests == 1, "once, until a frame is drawn again")
        rest.frameDrawn {
            counter.rests += 1
            return true
        }
        await waited(.milliseconds(450))
        #expect(counter.rests == 2)
    }

    @Test func `a terminal that stops is not told to rest`() async {
        let counter = Counter()
        let rest = FrameRest(after: .milliseconds(100))
        rest.frameDrawn {
            counter.rests += 1
            return true
        }
        rest.cancel()
        await waited(.milliseconds(300))
        #expect(counter.rests == 0)
    }

    @Test func `a renderer that could not let everything go is asked again, a few times and no more`() async {
        let counter = Counter()
        let rest = FrameRest(after: .milliseconds(60))
        rest.frameDrawn {
            counter.rests += 1
            return counter.rests == 3
        }
        await waited(.milliseconds(700))
        #expect(counter.rests == 3, "until it had let go")

        let never = Counter()
        let stubborn = FrameRest(after: .milliseconds(40))
        stubborn.frameDrawn {
            never.rests += 1
            return false
        }
        await waited(.milliseconds(900))
        #expect(never.rests == FrameRest.tries)
    }
}
