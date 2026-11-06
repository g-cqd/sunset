import AemiTestKit
import Testing

@testable import SunsetCore

@Suite("Screen: differential against a naive model") struct ScreenDifferentialTests {
    @Test func `printable ASCII with CR LF BS and TAB matches the naive model, however the input is cut`() {
        var random = SeededRNG(seed: 11)
        let pool: [UInt8] = Array(0x20 ... 0x7E) + [0x0D, 0x0A, 0x08, 0x09, 0x0A, 0x0D]
        for _ in 0 ..< 400 {
            let columns = 1 + random.below(30)
            let rows = 1 + random.below(8)
            let input = (0 ..< random.below(400)).map { _ in pool[random.below(pool.count)] }
            var naive = NaiveScreen(columns: columns, rows: rows)
            for byte in input { naive.feed(byte) }

            var terminal = Terminal(columns: columns, rows: rows)
            var offset = 0
            while offset < input.count {
                let end = min(input.count, offset + 1 + random.below(40))
                input[offset ..< end].withUnsafeBufferPointer { terminal.feed($0.span) }
                offset = end
            }
            let lines = (0 ..< rows).map { terminal.screen.text(row: $0) }
            #expect(lines == naive.lines, "\(columns)x\(rows) \(input)")
            #expect([terminal.screen.cursorRow, terminal.screen.cursorColumn] == [naive.y, naive.x])
        }
    }
}
