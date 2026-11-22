import AemiTestKit
import Foundation
import SunsetRuntime
import Testing

/// A test owns the time and the tasks of what it runs.
@Suite("The runtime's seams")
struct RuntimeTests {
    @Test func `a sleep waits for the test's clock, and a task started is waited for`() async throws {
        let clock = TestClock()
        let spy = TaskProviderSpy()
        let runtime = Runtime(
            tasks: spy,
            clock: clock,
            uptime: { clock.now.offset },
            now: { Date(timeIntervalSince1970: 0) }
        )
        let woke = Flag()
        runtime.task {
            await runtime.sleep(for: .seconds(30))
            woke.set()
        }
        try await clock.waitForSleepers(atLeast: 1)
        #expect(!woke.value, "no real time passes")
        clock.advance(by: .seconds(30))
        try await spy.waitForAllTasks()
        #expect(woke.value && runtime.uptime() == .seconds(30) && runtime.now() == Date(timeIntervalSince1970: 0))
    }
}
