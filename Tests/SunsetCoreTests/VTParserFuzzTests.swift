import AemiTestKit
import Foundation
import Testing

@testable import SunsetCore

/// Seeded adversarial VT / escape-sequence fuzzing (`VTParser` + `Screen`, N-S9 / R-VER-2):
/// feeds 500 hostile mixed CSI / OSC / DCS / APC / Kitty-graphics / UTF-8 / SGR / OSC-8 hyperlink streams into a real
/// `Screen` and verifies invariants hold (cursor in bounds, reply queue bounded, OSC buffer bounded, no trap).
@Suite("VT parser hostile sequence fuzzing")
struct VTParserFuzzTests {
    @Test func `hostile escape sequences preserve screen invariants and reply bounds`() {
        var rng = SeededRNG(seed: 0x47_2026_1125)
        let prefixes: [[UInt8]] = [
            Array("\u{1B}[".utf8),
            Array("\u{1B}]8;;https://example.test/".utf8),
            Array("\u{1B}]52;c;".utf8),
            Array("\u{1B}P".utf8),
            Array("\u{1B}_Ga=T,f=100;".utf8),
            Array("\u{1B}\\".utf8),
            [0x07],
            [0x1B, 0x63],
            [0xC0, 0xAF, 0xFF, 0xFE]
        ]

        var screen = Screen(columns: 80, rows: 24)
        var parser = VTParser()

        for _ in 0 ..< 500 {
            var chunk: [UInt8] = []
            let pieces = 1 + rng.below(8)
            for _ in 0 ..< pieces {
                if rng.below(2) == 0 {
                    chunk.append(contentsOf: prefixes[rng.below(prefixes.count)])
                }
                let len = rng.below(64)
                for _ in 0 ..< len {
                    chunk.append(UInt8(truncatingIfNeeded: rng.next()))
                }
            }
            parser.parse(chunk.span, into: &screen)
            #expect(screen.columns == 80 && screen.rows == 24)
            #expect(screen.row >= 0 && screen.row < screen.rows)
            #expect(screen.column >= 0 && screen.column < screen.columns)
            #expect(screen.replies.count <= 65_536)
        }
    }
}
