import AemiTestKit
import Testing

@testable import SunsetCore

/// Bytes that steer the parser: introducers, separators, terminators, controls, UTF-8 lead and continuation bytes, letters.
private let alphabet: [UInt8] =
    [
        0x1B, 0x1B, 0x5B, 0x5B, 0x5D, 0x50, 0x5F, 0x5E, 0x58, 0x5C, 0x3B, 0x3B, 0x3A, 0x3F, 0x3E, 0x20, 0x24, 0x31,
        0x32, 0x30, 0x39, 0x6D, 0x48, 0x71, 0x07, 0x18, 0x1A, 0x0A, 0x0D, 0x7F, 0x41, 0x61, 0xC2, 0x9C, 0x9B, 0x9D,
        0xE2, 0x82, 0xAC, 0xF0, 0x9F, 0x98, 0x80, 0xFF, 0xED, 0xA0
    ]

private func randomStream(_ random: inout SeededRNG, length: Int) -> [UInt8] {
    (0 ..< length)
        .map { _ in
            random.below(8) == 0 ? UInt8(truncatingIfNeeded: random.next()) : alphabet[random.below(alphabet.count)]
        }
}

@Suite("VT parser properties") struct VTParserPropertyTests {
    @Test func `how the input is cut never changes what is reported`() {
        var random = SeededRNG(seed: 1)
        for _ in 0 ..< 3000 {
            let input = randomStream(&random, length: 1 + random.below(60))
            let whole = parse(input, maxStringLength: 16)
            let cuts = (0 ..< random.below(8)).map { _ in 1 + random.below(7) }
            #expect(parse(input, pieces: cuts, maxStringLength: 16) == whole, "input \(input), cuts \(cuts)")
            #expect(
                parse(input, pieces: Array(repeating: 1, count: input.count), maxStringLength: 16) == whole,
                "byte by byte: \(input)"
            )
        }
    }

    @Test func `strings are balanced and sequences are whole whatever the input`() {
        var random = SeededRNG(seed: 2)
        for _ in 0 ..< 3000 {
            let input = randomStream(&random, length: 1 + random.below(80))
            var open = false
            for event in parse(input, maxStringLength: 16) {
                switch event {
                    case .stringStart:
                        #expect(!open, "a string began inside a string: \(input)")
                        open = true
                    case .stringBytes:
                        #expect(open, "string bytes outside a string: \(input)")
                    case .stringEnd:
                        #expect(open, "a string ended that had not begun: \(input)")
                        open = false
                    default:
                        #expect(!open, "a sequence was reported inside a string: \(input)")
                }
            }
        }
    }

    @Test func `string content never exceeds the limit`() {
        var random = SeededRNG(seed: 3)
        for _ in 0 ..< 2000 {
            let input = [0x1B, 0x5D] + randomStream(&random, length: 1 + random.below(100))
            var total = 0
            var open = false
            for event in parse(input, maxStringLength: 12) {
                switch event {
                    case .stringStart: (open, total) = (true, 0)
                    case .stringBytes(let bytes): total += bytes.count
                    case .stringEnd: open = false
                    default: break
                }
                #expect(total <= 12, "\(input)")
            }
            _ = open
        }
    }

    @Test func `printable text round-trips through any cut of valid UTF-8`() {
        var random = SeededRNG(seed: 4)
        let pool: [Unicode.Scalar] = [
            "a", "Z", " ", "~", "é", "€", "あ", "😀", "\u{10FFFF}", "\u{E000}", "\u{A0}", "\u{A1}"
        ]
        for _ in 0 ..< 500 {
            let scalars = (0 ..< 1 + random.below(40)).map { _ in pool[random.below(pool.count)] }
            let string = String(String.UnicodeScalarView(scalars))
            let cuts = (0 ..< random.below(6)).map { _ in 1 + random.below(5) }
            #expect(parse(string, pieces: cuts) == scalars.map { .text($0) })
        }
    }
}
