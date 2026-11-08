import SunsetCore
import Testing

@testable import SunsetHost

@Suite("History packing in a session", .serialized) struct HistoryPackingSessionTests {
    private func waitForLines(_ session: TerminalSession, last: String) async -> Bool {
        let deadline = ContinuousClock.now + .seconds(15)
        while ContinuousClock.now < deadline {
            let screen = await session.takeSnapshot()
            if (0 ..< screen.rows).contains(where: { screen.text(row: $0) == last }) { return true }
            try? await Task.sleep(for: .milliseconds(20))
        }
        return false
    }

    private func history(_ screen: Screen) -> [String] {
        (0 ..< screen.scrollbackCount).map { screen.scrollbackText(line: $0) }
    }

    @Test func `packing the history of a session leaves every line as it was, and makes it smaller`() async throws {
        let session = try TerminalSession(
            ["/bin/sh", "-c", "seq 1 6000; sleep 30"],
            columns: 80,
            rows: 24,
            scrollbackLimit: 10_000
        )
        await session.start()
        #expect(await waitForLines(session, last: "6000"))
        let before = await session.takeSnapshot()
        let lines = history(before)
        #expect(lines.count > 5000 && session.historyFootprint().packedChunks == 0)
        let hot = session.historyFootprint().hotCells
        var packed = 0
        while true {
            let step = session.packHistory(keepingRecent: 2, limit: 8)
            if step == 0 { break }
            packed += step
        }
        let footprint = session.historyFootprint()
        #expect(packed > 30 && footprint.packedChunks == packed)
        #expect(footprint.hotCells < hot / 4 && footprint.packedBytes < hot * 8 / 4)
        #expect(history(await session.takeSnapshot()) == lines)
        session.releaseDecodedHistory()
        #expect(history(await session.takeSnapshot()) == lines)
    }

    @Test func `output after packing is added and read like any other`() async throws {
        let session = try TerminalSession(
            ["/bin/sh", "-c", "seq 1 3000; sleep 1; seq 3001 3100; sleep 30"],
            columns: 80,
            rows: 24
        )
        await session.start()
        #expect(await waitForLines(session, last: "3000"))
        _ = session.packHistory(keepingRecent: 1, limit: .max)
        #expect(await waitForLines(session, last: "3100"))
        let lines = history(await session.takeSnapshot())
        // 3100 lines and the blank line the cursor is on make 3101 rows, 24 of them on the screen.
        #expect(lines.count == 3101 - 24 && lines.first == "1" && lines.last == "3077")
        #expect(lines == (1 ... 3077).map(String.init))
    }
}
