import AemiKernel
import AemiTestKit
import SunsetRuntime
import SunsetTestSupport
import Testing

@testable import SunsetCore
@testable import SunsetTerminalModel

/// The terminal's clock for Kitty animations (`AnimationPlayback`), run on a test clock against a real screen: frames
/// change at their gaps, each change asks for one frame, nothing runs while the terminal is hidden or nothing plays, and
/// an animation started or sped up during a long wait is not held back by it.
@MainActor
@Suite("Kitty animation playback, on the terminal's clock")
struct AnimationPlaybackTests {
    /// What the driver did, in order: looked at whether the terminal is shown, or ticked the screen at a time.
    enum Event: Sendable, Equatable {
        case tick(Int64, Screen.AnimationTick)
        case hidden
    }

    /// The screen, whether it is shown, and the frames asked for: what the model holds.
    @MainActor final class Pane {
        var terminal = Terminal(columns: 10, rows: 4)
        var visible = true
        var frames = 0
        let events = AsyncStream<Event>.makeStream()
        let wakes = TerminalWakes()

        init() {
            terminal.setCellPixelSize(width: 2, height: 1)
        }

        func send(_ control: String, _ pixels: [UInt8] = []) {
            let payload = pixels.isEmpty ? "" : ";" + Base64.encodedString(pixels)
            terminal.feed("\u{1B}_G\(control)\(payload)\u{1B}\\")
            _ = terminal.takeReplies()
        }

        /// The next thing the driver did; a test fails, it does not hang, when it did nothing.
        func next() async throws -> Event {
            let stream = events.stream
            let event = await withDeadline(within: TestTime.guardTime) {
                var iterator = stream.makeAsyncIterator()
                return await iterator.next()
            }
            return try #require(event ?? nil, "the driver did nothing")
        }

        func current(_ id: UInt32) -> Int? {
            terminal.screen.graphics.images[id]?.animation?.currentFrame
        }
    }

    private static let red: [UInt8] = [255, 0, 0, 255, 255, 0, 0, 255]
    private static let blue: [UInt8] = [0, 0, 255, 255, 0, 0, 255, 255]

    /// Image `id`, two frames `gap` milliseconds apart, playing: `loops` 1 is forever.
    private func animation(_ pane: Pane, id: Int, gap: Int, loops: Int = 1) {
        pane.send("a=T,q=2,i=\(id),f=32,s=2,v=1", Self.red)
        pane.send("a=f,q=2,i=\(id),z=\(gap),s=2,v=1", Self.blue)
        pane.send("a=a,q=2,i=\(id),r=1,z=\(gap),v=\(loops),s=3")
    }

    private func start(_ pane: Pane, _ time: TestTime) -> Task<Void, Never> {
        time.runtime.task(role: .observation) {
            await AnimationPlayback.run(
                runtime: time.runtime,
                wakes: pane.wakes.animation.stream,
                wake: pane.wakes.animation.continuation,
                isVisible: {
                    if !pane.visible { pane.events.continuation.yield(.hidden) }
                    return pane.visible
                },
                advance: { now in
                    let tick = pane.terminal.advanceAnimations(nowMilliseconds: now)
                    pane.events.continuation.yield(.tick(now, tick))
                    return tick
                },
                changed: { pane.frames += 1 }
            )
        }
    }

    @Test func `frames change at their gaps, one frame asked for each, and the spent loop waits without a timer`()
        async throws
    {
        let time = TestTime()
        let pane = Pane()
        animation(pane, id: 1, gap: 40, loops: 2)
        let mark = time.mark()
        let task = start(pane, time)
        #expect(try await pane.next() == .tick(0, .init(changed: false, next: 40)))
        try await time.waited(since: mark)
        try await time.passStillWaiting(.milliseconds(40))
        #expect(try await pane.next() == .tick(40, .init(changed: true, next: 80)))
        #expect(pane.current(1) == 2 && pane.frames == 1, "frames count from 1")
        try await time.passStillWaiting(.milliseconds(40))
        #expect(try await pane.next() == .tick(80, .init(changed: true, next: 120)))
        try await time.passStillWaiting(.milliseconds(40))
        #expect(try await pane.next() == .tick(120, .init(changed: true, next: 160)))
        time.advance(.milliseconds(40))
        #expect(try await pane.next() == .tick(160, .init(changed: false, next: nil)), "the loop is spent")
        #expect(pane.frames == 3)
        task.cancel()
        try await time.passToEnd(.zero)
    }

    @Test func `hidden, nothing ticks; shown again, it goes on from where it was`() async throws {
        let time = TestTime()
        let pane = Pane()
        animation(pane, id: 1, gap: 40)
        pane.visible = false
        let task = start(pane, time)
        #expect(try await pane.next() == .hidden)
        time.advance(.seconds(10))
        pane.visible = true
        let mark = time.mark()
        pane.wakes.yieldAll()
        #expect(
            try await pane.next() == .tick(10_000, .init(changed: false, next: 10_040)),
            "timed from when it is seen"
        )
        try await time.waited(since: mark)
        try await time.passStillWaiting(.milliseconds(40))
        #expect(try await pane.next() == .tick(10_040, .init(changed: true, next: 10_080)))
        task.cancel()
        try await time.passToEnd(.zero)
    }

    @Test func `an animation started during a long wait is played at its own pace`() async throws {
        let time = TestTime()
        let pane = Pane()
        animation(pane, id: 1, gap: 2_000)
        let mark = time.mark()
        let task = start(pane, time)
        #expect(try await pane.next() == .tick(0, .init(changed: false, next: 2_000)))
        try await time.waited(since: mark)
        time.advance(.milliseconds(100))
        animation(pane, id: 2, gap: 40)
        pane.wakes.yieldAll()
        #expect(try await pane.next() == .tick(100, .init(changed: false, next: 140)), "woken by the output")
        try await time.passStillWaiting(.milliseconds(40))
        #expect(try await pane.next() == .tick(140, .init(changed: true, next: 180)))
        #expect(pane.current(2) == 2 && pane.current(1) == 1)
        task.cancel()
        try await time.passToEnd(.zero)
    }

    @Test func `cancelled, it ends with its timer`() async throws {
        let time = TestTime()
        let pane = Pane()
        animation(pane, id: 1, gap: 40)
        let mark = time.mark()
        let task = start(pane, time)
        _ = try await pane.next()
        try await time.waited(since: mark)
        task.cancel()
        try await time.passToEnd(.zero)
        #expect(pane.frames == 0)
    }
}
