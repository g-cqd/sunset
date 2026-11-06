import Testing

@testable import SunsetHost

@Suite("PTY idle cost", .serialized) struct PTYIdleTests {
    @Test func `waiting for output of a program that prints nothing does not wake the reader`() async throws {
        let process = try PTYProcess.spawn(["/bin/sleep", "5"], environment: [:], columns: 80, rows: 24, directory: nil)
        let reading = Task { await process.read() }
        try await Task.sleep(for: .milliseconds(600))
        #expect(process.readWakeups <= 1, "woke \(process.readWakeups) times in 600 ms")
        reading.cancel()
        let result = await reading.value
        #expect(result == nil)
        process.hangUp()
    }

    @Test func `a read that is cancelled ends at once, not at the next timeout`() async throws {
        let process = try PTYProcess.spawn(["/bin/sleep", "5"], environment: [:], columns: 80, rows: 24, directory: nil)
        let reading = Task { await process.read() }
        try await Task.sleep(for: .milliseconds(100))
        let start = ContinuousClock.now
        reading.cancel()
        _ = await reading.value
        #expect(ContinuousClock.now - start < .milliseconds(30), "took \(ContinuousClock.now - start)")
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
        try await Task.sleep(for: .milliseconds(100))
        first.cancel()
        #expect(await first.value == nil)
        var text = ""
        while text.count < 5, let bytes = await process.read() { text += String(decoding: bytes, as: UTF8.self) }
        #expect(text == "hello")
    }
}
