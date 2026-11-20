import AemiTestKit
import Foundation
import SunsetRuntime
import SunsetTestSupport
import Testing

@testable import SunsetAppCore

/// The quit's last work (clearing and sealing WebKit's stores: ADR-0081, ADR-0103) was waited for by spinning the run loop
/// from inside a main-actor task (the quit asks first, `QuitGate.decide`): a main-actor task cannot start while one runs
/// there, so the work never ran and the five seconds always passed (seen 2026-11-19: no jar sealed after the owner's quit).
/// The quit now awaits the work, at most its limit.
@MainActor
@Suite("The quit's work: awaited, at most its limit")
struct QuitDeadlineTests {
    @Test func `from inside a main-actor task, the work runs and is awaited`() async throws {
        let time = TestTime()
        let latch = AsyncLatch()
        var ran = false
        // The work suspends until the test lets it go: it runs as a main-actor task that has to wait its turn.
        time.runtime.task { latch.open() }
        let finished = await QuitDeadline.wait(limit: .seconds(5), runtime: time.runtime) { @MainActor in
            try? await latch.wait()
            ran = true
        }
        #expect(ran && finished)
        try await time.settle()
    }

    @Test func `work that does not end in time is left: the quit goes on at the limit`() async throws {
        let time = TestTime()
        let mark = time.mark()
        var finished: Bool?
        let quitting = time.runtime.task { @MainActor in
            finished = await QuitDeadline.wait(limit: .seconds(5), runtime: time.runtime) { @MainActor in
                await time.runtime.sleep(for: .seconds(60))
            }
        }
        try await time.waited(since: mark, count: 2)
        time.advance(.seconds(5))
        await quitting.value
        #expect(finished == false)
        try await time.pass(.seconds(55))
    }
}
