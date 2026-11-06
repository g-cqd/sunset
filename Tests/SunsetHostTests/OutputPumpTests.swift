import Testing

@testable import SunsetHost

@Suite("Output pump", .serialized) struct OutputPumpTests {
    private func spawn(_ script: String) throws -> PTYProcess {
        try PTYProcess.spawn(["/bin/sh", "-c", script], environment: [:], columns: 80, rows: 24, directory: nil)
    }

    /// Takes everything until the output has ended.
    private func drain(_ pump: OutputPump, limit: Int = 64 * 1024) async -> [UInt8] {
        var all: [UInt8] = []
        for await _ in pump.signals {
            while true {
                let batch = pump.take(limit: limit)
                if batch.isEmpty { break }
                all += batch
            }
        }
        all += pump.take(limit: .max)
        return all
    }

    @Test func `every byte arrives, in order, and the stream ends when the program does`() async throws {
        let process = try spawn("i=0; while [ $i -lt 5000 ]; do echo line$i; i=$((i+1)); done")
        process.pump.start()
        let text = String(decoding: await drain(process.pump), as: UTF8.self)
        let lines = text.split(separator: "\r\n").map(String.init)
        #expect(lines == (0 ..< 5000).map { "line\($0)" })
    }

    @Test func `while the consumer is busy, what arrives is coalesced into bigger batches`() async throws {
        let process = try spawn("head -c 4000000 /dev/zero | tr '\\0' x")
        process.pump.start()
        var batches = 0
        var total = 0
        for await _ in process.pump.signals {
            // The consumer's work (the parse): the pseudo-terminal hands out about 1.3 KiB per read, and the reader goes on while this runs.
            try await Task.sleep(for: .milliseconds(3))
            let batch = process.pump.take(limit: 1 << 20)
            if !batch.isEmpty { batches += 1 }
            total += batch.count
        }
        total += process.pump.take(limit: .max).count
        #expect(total == 4_000_000)
        #expect(batches < 200, "\(batches) batches")
    }

    @Test func `a consumer that does not take makes the reader stop at the limit, and nothing is lost`() async throws {
        let process = try spawn("head -c 8000000 /dev/zero | tr '\\0' x")
        process.pump.start()
        try await Task.sleep(for: .milliseconds(700))
        let held = process.pump.pendingBytes
        #expect(held >= PTYProcess.outputBacklogLimit, "the reader stopped early at \(held)")
        #expect(held <= PTYProcess.outputBacklogLimit + 256 * 1024, "the buffer grew to \(held)")
        let rest = await drain(process.pump)
        #expect(rest.count == 8_000_000)
    }

    @Test func `a program that prints nothing does not wake the reader, and stopping ends the stream at once`()
        async throws
    {
        let process = try spawn("sleep 5")
        process.pump.start()
        try await Task.sleep(for: .milliseconds(500))
        #expect(process.pump.wakeups <= 2, "woke \(process.pump.wakeups) times")
        let start = ContinuousClock.now
        process.pump.stop()
        for await _ in process.pump.signals {}
        #expect(ContinuousClock.now - start < .milliseconds(100))
        process.hangUp()
    }
}
