import Testing

@testable import SunsetHost

@Suite("Foreground command", .serialized) struct ForegroundCommandTests {
    /// Polls for at most `seconds` (a bound on a failing test, not a wait a passing one depends on).
    private func eventually(seconds: Int = 10, _ condition: () -> Bool) async -> Bool {
        let deadline = ContinuousClock.now + .seconds(seconds)
        while ContinuousClock.now < deadline {
            if condition() { return true }
            try? await Task.sleep(for: .milliseconds(25))
        }
        return condition()
    }

    @Test
    func `an idle shell has no foreground command, a program it runs is named, and the shell is back when it ends`()
        async throws
    {
        let session = try TerminalSession(["/bin/sh", "-i"], columns: 80, rows: 24, environment: ["PS1": "$ "])
        await session.start()
        #expect(await eventually { session.foregroundCommand() == nil })
        await session.send(Array("sleep 30\n".utf8))
        #expect(await eventually { session.foregroundCommand() == "sleep" })
        // Ctrl-C ends the program: the shell is the foreground group again.
        await session.send([0x03])
        #expect(await eventually { session.foregroundCommand() == nil })
    }

    @Test func `a session whose program has ended has no foreground command`() async throws {
        let session = try TerminalSession(["/bin/sh", "-c", "exit 0"], columns: 80, rows: 24)
        await session.start()
        #expect(await eventually { session.foregroundCommand() == nil })
    }
}
