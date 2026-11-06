import Testing

@testable import SunsetCore

/// The parser decodes a whole UTF-8 sequence in one step when all of it is in the input; fed one byte at a time it can only use the state machine. Both
/// ways must give the same events, for valid text and for every kind of broken text.
@Suite("Parser: UTF-8 decoded in one step or byte by byte") struct VTParserUTF8InlineTests {
    private struct Random {
        var state: UInt64
        mutating func next(_ bound: Int) -> Int {
            state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
            return Int((state >> 33) % UInt64(bound))
        }
    }

    private func events(_ bytes: [UInt8], chunks: [Int]) -> [Event] {
        var parser = VTParser()
        var recorder = Recorder()
        var offset = 0
        var turn = 0
        while offset < bytes.count {
            let end = min(offset + max(1, chunks[turn % chunks.count]), bytes.count)
            bytes[offset ..< end].withUnsafeBufferPointer { parser.parse($0.span, into: &recorder) }
            offset = end
            turn += 1
        }
        return recorder.events
    }

    @Test func `random text with every kind of broken sequence parses the same whole, cut up, and byte by byte`() {
        var random = Random(state: 42)
        // The bytes that matter: leads of every length, continuations, the edges of the ranges, C1 controls, ASCII, escape.
        let interesting: [UInt8] = [
            0x41, 0x20, 0x1B, 0x5B, 0x6D, 0x80, 0x8F, 0x90, 0x9B, 0x9C, 0x9F, 0xA0, 0xBF, 0xC0, 0xC1, 0xC2, 0xDF, 0xE0,
            0xE1, 0xEC,
            0xED, 0xEE, 0xEF, 0xF0, 0xF1, 0xF3, 0xF4, 0xF5, 0xFF
        ]
        for _ in 0 ..< 3000 {
            let length = 1 + random.next(40)
            let bytes = (0 ..< length)
                .map { _ in
                    random.next(3) == 0 ? UInt8(random.next(256)) : interesting[random.next(interesting.count)]
                }
            let whole = events(bytes, chunks: [bytes.count])
            #expect(events(bytes, chunks: [1]) == whole, "byte by byte differs for \(bytes)")
            #expect(events(bytes, chunks: [3, 1, 5, 2]) == whole, "cut up differs for \(bytes)")
        }
    }

    @Test func `valid text of every length comes out as the scalars it encodes`() {
        let text = "a é 日本語 😀 \u{10FFFF}\u{FFFF}\u{800}\u{7FF}\u{A0}"
        let bytes = Array(text.utf8)
        let printed = events(bytes, chunks: [bytes.count])
            .compactMap { event -> Unicode.Scalar? in
                if case .text(let scalar) = event { scalar } else { nil }
            }
        #expect(String(String.UnicodeScalarView(printed)) == text)
    }
}
