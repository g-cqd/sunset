import AemiTestKit
import Foundation
import SunsetTestSupport
import Synchronization
import Testing

/// The test kit's waits (ADR-0087): each ends as soon as what it waits for holds, says what and where when it does not,
/// and is the test's to drive on a `TestClock`.
@Suite("Waiting tools") struct WaitingToolsTests {
    @Test func `a poll ends at the first look that holds, and times out naming what it waited for`() async throws {
        let looks = Mutex(0)
        try await Poll.until("three looks") {
            looks.withLock {
                $0 += 1
                return $0 == 3
            }
        }
        #expect(looks.withLock { $0 } == 3)
        let error = try #require(
            await #expect(throws: Poll.Timeout.self) {
                try await Poll.until("never", within: .milliseconds(30)) { false }
            }
        )
        #expect(
            error.description.hasPrefix("never did not hold within") && error.description.contains("WaitingToolsTests")
        )
    }

    @Test func `on a test clock, a poll looks again only when the clock moves, and its limit is the clock's`()
        async throws
    {
        let clock = TestClock()
        let looks = Mutex(0)
        let polling = Task {
            try await Poll.until(within: .seconds(1), every: .milliseconds(100), clock: clock) {
                looks.withLock {
                    $0 += 1
                    return false
                }
            }
        }
        var mark = clock.registrationMark()
        for expected in 1 ... 3 {
            try await clock.waitForSleepers(1, after: mark)
            #expect(looks.withLock { $0 } == expected)
            mark = clock.registrationMark()
            clock.advance(by: .milliseconds(100))
        }
        clock.advance(by: .seconds(1))
        await #expect(throws: Poll.Timeout.self) { try await polling.value }
    }

    @Test func `a deadline gives the answer when it comes first, nil when the limit does`() async throws {
        #expect(await Deadline.first(within: .seconds(10)) { 42 } == 42)
        let latch = AsyncLatch()
        let clock = TestClock()
        let waiting = Task {
            await Deadline.first(within: .seconds(1), clock: clock) {
                try? await latch.wait()
                return 1
            }
        }
        // The deadline's own sleep is the harness's: not one of the sleepers a test waits for.
        try await clock.waitForUntrackedSleepers(atLeast: 1)
        #expect(clock.sleeperCount == 0)
        clock.advance(by: .seconds(1))
        #expect(await waiting.value == nil)
        latch.open()
    }

    @Test func `a key-value probe sees the value it starts with and each change, without polling`() async throws {
        let object = Observed()
        let probe = KeyValueProbe(object, \.number)
        try await probe.wait(until: { $0 == 0 })
        // Changed on another thread, as AppKit and WebKit do.
        Thread.detachNewThread { for value in 1 ... 5 { object.number = value } }
        try await probe.wait(until: { $0 == 5 })
        #expect(probe.values.events == [0, 1, 2, 3, 4, 5])
        try await probe.wait(history: { $0.contains(2) && $0.last == 5 })
        await #expect(throws: AsyncEventProbeTimeoutError.self) {
            try await probe.wait(until: { $0 == 6 }, within: .milliseconds(30))
        }
    }
}
