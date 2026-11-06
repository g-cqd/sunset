import Testing

@testable import SunsetCore

@Suite("Scrollback storage") struct ScrollbackStorageTests {
    private func line(_ value: UInt32, columns: Int = 4) -> ArraySlice<Cell> {
        ArraySlice((0 ..< columns).map { _ in Cell(scalar: value, width: .narrow, style: 0) })
    }

    private func filled(lines: Int, limit: Int, columns: Int = 4) -> Scrollback {
        var history = Scrollback(columns: columns, limit: limit)
        for index in 0 ..< lines { history.push(line(UInt32(index + 1), columns: columns), wrapped: index % 3 == 0) }
        return history
    }

    @Test func `lines come back in the order they were pushed, across many wraps of a small limit`() {
        let history = filled(lines: 1000, limit: 300)
        #expect(history.count == 300)
        for index in [0, 1, 127, 128, 129, 255, 256, 299] {
            #expect(history[index, 0].scalar == UInt32(1000 - 300 + index + 1), "line \(index)")
            #expect(history.isWrapped(index) == ((1000 - 300 + index) % 3 == 0), "wrapped \(index)")
        }
        #expect(history.evicted == 700)
    }

    @Test func `the storage is bounded: the limit plus less than one chunk`() {
        let history = filled(lines: 5000, limit: 1000)
        #expect(history.storedLines <= 1000 + Scrollback.chunkLines)
        #expect(history.storedLines >= 1000)
    }

    @Test func `a copy shares every line it holds, and writing to the original copies at most the newest chunk`() {
        var history = filled(lines: 2000, limit: 2000)
        let copy = history
        history.push(line(9999), wrapped: false)
        for index in [0, 500, 1000, 1500, 1871] {
            #expect(history.sharesStorage(line: index, with: copy), "line \(index) is still shared")
        }
        #expect(copy.count == 2000 && history.count == 2000, "the history is full, so the oldest left")
        #expect(copy[1999, 0].scalar == 2000, "the copy is not touched by the write")
        #expect(history[1999, 0].scalar == 9999)
    }

    @Test func `a copy of a full history stays shared while the original keeps rolling`() {
        var history = filled(lines: 3000, limit: 1000)
        let copy = history
        for index in 0 ..< 50 { history.push(line(UInt32(10_000 + index)), wrapped: false) }
        let before = copy[0, 0].scalar
        #expect(before == 2001 && copy.count == 1000, "the copy still shows what it showed")
        #expect(history[0, 0].scalar == 2051)
    }

    @Test func `style rewriting reaches every stored line, newest first`() {
        var history = Scrollback(columns: 2, limit: 500)
        for index in 0 ..< 400 {
            history.push(
                [
                    Cell(scalar: 65, width: .narrow, style: UInt16(index % 7 + 1)),
                    Cell(scalar: 66, width: .narrow, style: 3)
                ],
                wrapped: false
            )
        }
        history.mapStyles { $0 + 10 }
        #expect(
            history[0, 0].styleID == 11 && history[399, 1].styleID == 13
                && history[200, 0].styleID == UInt16(200 % 7 + 11)
        )
    }

    @Test func `clearing counts the lines as gone and starts again`() {
        var history = filled(lines: 400, limit: 1000)
        history.removeAll()
        #expect(history.count == 0 && history.evicted == 400 && history.storedLines == 0)
        history.push(line(7), wrapped: false)
        #expect(history.count == 1 && history[0, 0].scalar == 7)
    }

    @Test func `a limit of zero keeps nothing and counts everything as gone`() {
        let history = filled(lines: 10, limit: 0)
        #expect(history.count == 0 && history.evicted == 10)
    }
}
