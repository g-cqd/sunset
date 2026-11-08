import Testing

@testable import SunsetCore

@Suite("Adopting packed history") struct ScreenHistoryAdoptionTests {
    private func fed(lines: Int) -> Terminal {
        var terminal = Terminal(columns: 20, rows: 4, scrollbackLimit: 10_000)
        // A line of one letter repeated, the letter changing from line to line: `WordRunCodec` shrinks runs.
        for line in 1 ... lines {
            terminal.feed(String(repeating: String(UnicodeScalar(UInt8(97 + line % 26))), count: 16) + "\r\n")
        }
        return terminal
    }

    @Test func `a copy taken before packing takes the packed history of the same lines, and reads the same`() {
        var terminal = fed(lines: 1000)
        var old = terminal.screen
        let texts = (0 ..< old.scrollbackCount).map { old.scrollbackText(line: $0) }
        terminal.packHistory(using: WordRunCodec(), keepingRecent: 1, limit: .max)
        #expect(old.historyFootprint.packedChunks == 0)
        let adopted = old.adoptHistory(from: terminal.screen)
        #expect(adopted)
        #expect(old.historyFootprint.packedChunks == terminal.screen.historyFootprint.packedChunks)
        // At most the newest full chunk and the one being filled are still cells: 2 chunks of 128 lines of 16 cells.
        #expect(old.historyFootprint.packedChunks > 0 && old.historyFootprint.hotCells <= 2 * 128 * 16)
        #expect((0 ..< old.scrollbackCount).map { old.scrollbackText(line: $0) } == texts)
    }

    @Test func `history that is not the same lines is not adopted`() {
        var terminal = fed(lines: 1000)
        var old = terminal.screen
        terminal.feed("one more\r\n")
        terminal.packHistory(using: WordRunCodec(), keepingRecent: 1, limit: .max)
        let adopted = old.adoptHistory(from: terminal.screen)
        #expect(!adopted)
        #expect(old.historyFootprint.packedChunks == 0)
    }
}
