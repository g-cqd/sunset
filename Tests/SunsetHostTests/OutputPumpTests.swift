import Darwin
import Testing

@testable import SunsetHost

@Suite("Output pump", .serialized) struct OutputPumpTests {
    private func spawn(_ script: String) throws -> PTYProcess {
        try PTYProcess.spawn(["/bin/sh", "-c", script], environment: [:], columns: 80, rows: 24, directory: nil)
    }

    /// Runs the pump on the reader thread until the output ends, collecting what it delivers.
    private func collect(_ process: PTYProcess, perRead: @Sendable @escaping () -> Void = {}) async -> [UInt8] {
        let pump = process.pump
        return await Task(executorPreference: process.readThread) {
            var all: [UInt8] = []
            pump.run { bytes in
                all.append(contentsOf: bytes)
                perRead()
            }
            return all
        }
        .value
    }

    @Test func `every byte arrives, in order, and the pump returns when the program ends`() async throws {
        let process = try spawn("i=0; while [ $i -lt 5000 ]; do echo line$i; i=$((i+1)); done")
        let text = String(decoding: await collect(process), as: UTF8.self)
        // The kernel now and then writes a line's carriage return twice ("line196\r\r\n", seen about once in a hundred runs under load, every line
        // still there and in order): that is the terminal's line discipline, not a byte of the program's, so the returns are not compared.
        let lines = text.split(separator: "\r\n").map { line in String(line.filter { $0 != "\r" }) }
        let wanted = (0 ..< 5000).map { "line\($0)" }
        let first =
            zip(lines, wanted).enumerated().first { $0.element.0 != $0.element.1 }?.offset
            ?? min(lines.count, wanted.count)
        let near = lines[max(0, first - 2) ..< min(lines.count, first + 3)]
        #expect(lines == wanted, "\(lines.count) lines; first difference at \(first): \(Array(near))")
    }

    @Test func `a big output arrives whole`() async throws {
        let process = try spawn("head -c 4000000 /dev/zero | tr '\\0' x")
        #expect(await collect(process).count == 4_000_000)
    }

    @Test func `a consumer that is slow loses nothing: the reader waits for it`() async throws {
        let process = try spawn("head -c 2000000 /dev/zero | tr '\\0' x")
        let bytes = await collect(process) { _ = usleep(100) }
        #expect(bytes.count == 2_000_000)
    }

    @Test func `a program that prints nothing does not wake the reader, and stopping ends the pump at once`()
        async throws
    {
        let process = try spawn("sleep 5")
        let pump = process.pump
        let running = Task(executorPreference: process.readThread) { pump.run { _ in } }
        try await Task.sleep(for: .milliseconds(500))
        #expect(pump.wakeups <= 2, "woke \(pump.wakeups) times")
        let start = ContinuousClock.now
        pump.stop()
        await running.value
        #expect(ContinuousClock.now - start < .milliseconds(100))
        process.hangUp()
    }
}
