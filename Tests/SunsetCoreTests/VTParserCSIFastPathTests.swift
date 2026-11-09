import AemiTestKit
import Testing

@testable import SunsetCore

/// Whole control sequences in the input are parsed in one pass (`VTParser.wholeCSI`); the state machine stays the reference. Any input, cut anywhere,
/// must give the same events either way.
@Suite("Parser: control sequences parsed whole agree with the state machine") struct VTParserCSIFastPathTests {
    private static let pieces: [[UInt8]] = [
        Array("\u{1B}[".utf8), Array("\u{1B}[0m".utf8), Array("\u{1B}[38;5;123;48;2;10;20;30;1;3;4m".utf8),
        Array("\u{1B}[4:3m".utf8),
        Array("\u{1B}[?25h".utf8), Array("\u{1B}[>c".utf8), Array("\u{1B}[2 q".utf8),
        Array("\u{1B}[1;2;3;4;5;6;7;8;9;10;11;12;13;14;15;16;17m".utf8),
        Array("\u{1B}[;;m".utf8), Array("\u{1B}[:5m".utf8), Array("\u{1B}[99999999H".utf8), Array("\u{1B}[?1?2h".utf8),
        Array("\u{1B}[1 2m".utf8),
        Array("\u{1B}[1!p".utf8), Array("\u{1B}[1 !\"m".utf8), Array("\u{1B}[=5u".utf8), Array("\u{1B}[3".utf8),
        Array(";".utf8), Array("m".utf8),
        [0x1B], [0x5B], [0x18], [0x1A], [0x7F], [0x07], [0x0A], [0x0D], [0x9B], Array("text".utf8), Array("é日👍🏽".utf8),
        Array("\u{1B}]0;title\u{07}".utf8),
        Array("\u{1B}P1$qm\u{1B}\\".utf8), Array("\u{1B}(B".utf8), [0x1B, 0x5B, 0x31, 0x0A, 0x6D], [0xC2], [0x9C]
    ]

    private func events(_ bytes: [UInt8], cuts: [Int], fastPath: Bool) -> [Event] {
        var parser = VTParser()
        parser.csiFastPath = fastPath
        var recorder = Recorder()
        var start = 0
        for cut in cuts + [bytes.count] where cut >= start {
            bytes[start ..< cut].withUnsafeBufferPointer { parser.parse($0.span, into: &recorder) }
            start = cut
        }
        return recorder.events
    }

    @Test func `random input, cut anywhere, gives the same events with and without the fast path`() {
        var random = SeededRNG(seed: 77)
        for round in 0 ..< 3000 {
            var bytes: [UInt8] = []
            for _ in 0 ..< 1 + random.below(12) { bytes += Self.pieces[random.below(Self.pieces.count)] }
            if random.below(4) == 0 { bytes[random.below(bytes.count)] = UInt8(random.below(256)) }
            let cuts = (0 ..< random.below(4)).map { _ in random.below(bytes.count + 1) }.sorted()
            let slow = events(bytes, cuts: cuts, fastPath: false)
            let fast = events(bytes, cuts: cuts, fastPath: true)
            guard slow == fast else {
                Issue.record("round \(round): \(bytes) cut at \(cuts)\nslow \(slow)\nfast \(fast)")
                return
            }
        }
    }
}
