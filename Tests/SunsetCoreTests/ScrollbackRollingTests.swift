import Testing

@testable import SunsetCore

/// A full history rolls for as long as output comes: the oldest lines go, the newest are read back as written, and the memory stays bounded.
@Suite("Scrollback: a full history rolls") struct ScrollbackRollingTests {
    @Test func `thirty thousand lines through a history of three hundred: the last three hundred remain, in order`() {
        var history = Scrollback(columns: 12, limit: 300)
        for number in 0 ..< 30_000 {
            let text = Array("line \(number)".unicodeScalars).map { Cell(scalar: $0.value, width: .narrow, style: 0) }
            history.push(ArraySlice(text), wrapped: number % 7 == 0)
            if number % 5_000 == 4_999 { _ = history.pack(using: WordRunCodec(), keepingRecent: 1, limit: .max) }
        }
        #expect(history.count == 300)
        #expect(history.evicted == 29_700)
        for line in [0, 1, 150, 298, 299] {
            let number = 29_700 + line
            let cells = history.cells(line: line)
            let text = String(String.UnicodeScalarView(cells.compactMap { Unicode.Scalar($0.scalar) }))
            #expect(text == "line \(number)", "line \(line)")
            #expect(history.isWrapped(line) == (number % 7 == 0))
        }
        // The lines held, the gone chunks waiting to be removed included: bounded by the limit, a chunk being filled and the batch of gone ones.
        #expect(history.chunks.count <= 300 / Scrollback.chunkLines + 2 + 64)
        #expect(history.storedLines <= 300 + Scrollback.chunkLines)
    }
}
