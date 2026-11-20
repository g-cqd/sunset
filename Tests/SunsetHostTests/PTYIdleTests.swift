import SunsetTestSupport
import Testing

@testable import SunsetHost

@Suite("PTY idle cost", .serialized) struct PTYIdleTests {
    @Test func `waiting for output of a program that prints nothing does not wake the reader`() async throws {
        let process = try PTYProcess.spawn(["/bin/sleep", "5"], environment: [:], columns: 80, rows: 24, directory: nil)
        let reading = Task { await process.read() }
        // Nothing is to happen for a while: only time passing says so.
        await RealWait.pass(.milliseconds(600))
        #expect(process.readWakeups <= 1, "woke \(process.readWakeups) times in 600 ms")
        reading.cancel()
        let result = await reading.value
        #expect(result == nil)
        process.hangUp()
    }

    @Test func `a read that is cancelled ends at once, not at the next timeout`() async throws {
        let process = try PTYProcess.spawn(["/bin/sleep", "5"], environment: [:], columns: 80, rows: 24, directory: nil)
        let reading = Task { await process.read() }
        try await Poll.until("the read waiting") { process.readWaits >= 1 }
        let watch = Stopwatch()
        reading.cancel()
        _ = await reading.value
        // Stopping is prompt, not a poll's timeout later: no count says that.
        #expect(watch.elapsed < .milliseconds(30), "took \(watch.elapsed)")
        process.hangUp()
    }

    @Test func `output still arrives, and a second read after a cancelled one works`() async throws {
        let process = try PTYProcess.spawn(
            ["/bin/sh", "-c", "sleep 0.4; printf hello"],
            environment: [:],
            columns: 80,
            rows: 24,
            directory: nil
        )
        let first = Task { await process.read() }
        try await Poll.until("the read waiting") { process.readWaits >= 1 }
        first.cancel()
        #expect(await first.value == nil)
        var text = ""
        while text.count < 5, let bytes = await process.read() { text += String(decoding: bytes, as: UTF8.self) }
        #expect(text == "hello")
    }
}
