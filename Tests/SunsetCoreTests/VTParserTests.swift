import Testing

@testable import SunsetCore

/// What the parser reported, as values, so tests compare whole sequences. Printable runs are expanded to one event per character, because where a
/// run is cut depends on how the input was split and the meaning does not.
enum Event: Equatable {
    case text(Unicode.Scalar)
    case execute(UInt8)
    case escape(UInt8, [UInt8])
    case csi(marker: UInt8, parameters: [Int], subMask: UInt32, intermediates: [UInt8], final: UInt8)
    case stringStart(StringKind, header: [Int], marker: UInt8, intermediates: [UInt8], final: UInt8)
    case stringBytes([UInt8])
    case stringEnd(completed: Bool)
}

struct Recorder: VTSink {
    var events: [Event] = []

    mutating func printASCII(_ run: Span<UInt8>) {
        for index in run.indices { events.append(.text(Unicode.Scalar(run[index]))) }
    }
    mutating func print(_ scalar: Unicode.Scalar) { events.append(.text(scalar)) }
    mutating func execute(_ control: UInt8) { events.append(.execute(control)) }
    mutating func escape(_ intermediates: Intermediates, final: UInt8) {
        events.append(.escape(final, bytes(intermediates)))
    }
    mutating func csi(_ parameters: Parameters, marker: UInt8, intermediates: Intermediates, final: UInt8) {
        events.append(
            .csi(
                marker: marker,
                parameters: list(parameters),
                subMask: parameters.subParameterMask,
                intermediates: bytes(intermediates),
                final: final
            )
        )
    }
    mutating func stringStart(
        _ kind: StringKind,
        parameters: Parameters,
        marker: UInt8,
        intermediates: Intermediates,
        final: UInt8
    ) {
        events.append(
            .stringStart(
                kind,
                header: list(parameters),
                marker: marker,
                intermediates: bytes(intermediates),
                final: final
            )
        )
    }
    mutating func stringBytes(_ bytes: Span<UInt8>) {
        var piece: [UInt8] = []
        for index in bytes.indices { piece.append(bytes[index]) }
        // Pieces of one string are merged: how the input was cut must not show.
        if case .stringBytes(let before)? = events.last {
            events[events.count - 1] = .stringBytes(before + piece)
        } else {
            events.append(.stringBytes(piece))
        }
    }
    mutating func stringEnd(completed: Bool) { events.append(.stringEnd(completed: completed)) }

    private func list(_ parameters: Parameters) -> [Int] { (0 ..< parameters.count).map { parameters[$0] } }
    private func bytes(_ intermediates: Intermediates) -> [UInt8] {
        [intermediates.first, intermediates.second].prefix(intermediates.count).map { $0 }
    }
}

/// Parses `input` in pieces of the given sizes (the last piece takes the rest) and returns the events.
func parse(_ input: [UInt8], pieces: [Int] = [], maxStringLength: Int = 1 << 20) -> [Event] {
    var parser = VTParser(maxStringLength: maxStringLength)
    var sink = Recorder()
    var offset = 0
    for size in pieces + [input.count] where offset < input.count {
        let end = min(input.count, offset + max(1, size))
        input[offset ..< end]
            .withUnsafeBufferPointer { buffer in
                parser.parse(buffer.span, into: &sink)
            }
        offset = end
    }
    return sink.events
}

func parse(_ text: String, pieces: [Int] = [], maxStringLength: Int = 1 << 20) -> [Event] {
    parse(Array(text.utf8), pieces: pieces, maxStringLength: maxStringLength)
}

func text(_ string: String) -> [Event] { string.unicodeScalars.map { .text($0) } }

@Suite("VT parser") struct VTParserTests {
    @Test func `printable ASCII is text`() {
        #expect(parse("hi!") == text("hi!"))
    }

    @Test func `C0 controls are executed and DEL is ignored`() {
        #expect(
            parse("a\r\n\u{08}\u{7}\t\u{7F}b") == text("a") + [
                .execute(13), .execute(10), .execute(8), .execute(7), .execute(9)
            ] + text("b")
        )
    }

    @Test func `UTF-8 decodes to scalars, split anywhere`() {
        let input = "é€😀x"
        #expect(parse(input) == text(input))
        #expect(parse(input, pieces: [1, 1, 1, 1, 1, 1, 1]) == text(input))
    }

    @Test func `invalid UTF-8 gives one replacement per maximal invalid subpart`() {
        let r = Unicode.Scalar(0xFFFD)!
        #expect(parse([0x80]) == [.text(r)])  // a stray continuation byte
        #expect(parse([0xC0, 0x80]) == [.text(r), .text(r)])  // an overlong lead is invalid at once
        // A truncated three-byte sequence, then a byte that starts afresh.
        #expect(parse([0xE2, 0x82, 0x41]) == [.text(r)] + text("A"))
        #expect(parse([0xED, 0xA0, 0x80]) == [.text(r), .text(r), .text(r)])  // a surrogate
        #expect(parse([0xF4, 0x90, 0x80, 0x80]) == [.text(r), .text(r), .text(r), .text(r)])  // above U+10FFFF
        #expect(parse([0xF0, 0x9F]) == [])  // incomplete at the end of the input: kept for the next piece
    }

    @Test func `escape sequences with and without intermediates`() {
        #expect(parse("\u{1B}7") == [.escape(0x37, [])])
        #expect(parse("\u{1B}(0") == [.escape(0x30, [0x28])])
        #expect(parse("\u{1B} F") == [.escape(0x46, [0x20])])
    }

    @Test func `CSI with parameters, a marker and intermediates`() {
        #expect(parse("\u{1B}[H") == [.csi(marker: 0, parameters: [], subMask: 0, intermediates: [], final: 0x48)])
        #expect(
            parse("\u{1B}[1;31m") == [.csi(marker: 0, parameters: [1, 31], subMask: 0, intermediates: [], final: 0x6D)]
        )
        #expect(
            parse("\u{1B}[;5H") == [.csi(marker: 0, parameters: [0, 5], subMask: 0, intermediates: [], final: 0x48)]
        )
        #expect(
            parse("\u{1B}[?1049h") == [
                .csi(marker: 0x3F, parameters: [1049], subMask: 0, intermediates: [], final: 0x68)
            ]
        )
        #expect(
            parse("\u{1B}[>1u") == [.csi(marker: 0x3E, parameters: [1], subMask: 0, intermediates: [], final: 0x75)]
        )
        #expect(
            parse("\u{1B}[0 q") == [.csi(marker: 0, parameters: [0], subMask: 0, intermediates: [0x20], final: 0x71)]
        )
        #expect(
            parse("\u{1B}[?25$p") == [
                .csi(marker: 0x3F, parameters: [25], subMask: 0, intermediates: [0x24], final: 0x70)
            ]
        )
    }

    @Test func `colon sub-parameters are flagged`() {
        #expect(
            parse("\u{1B}[38:2::10:20:30m")
                == [
                    .csi(
                        marker: 0,
                        parameters: [38, 2, 0, 10, 20, 30],
                        subMask: 0b111110,
                        intermediates: [],
                        final: 0x6D
                    )
                ]
        )
    }

    @Test func `parameter values saturate at 65535`() {
        #expect(
            parse("\u{1B}[99999999999H") == [
                .csi(marker: 0, parameters: [65535], subMask: 0, intermediates: [], final: 0x48)
            ]
        )
    }

    @Test func `too many parameters or intermediates ignore the whole sequence`() {
        let many = (0 ..< 33).map(String.init).joined(separator: ";")
        #expect(parse("\u{1B}[\(many)mx") == text("x"))
        let thirtyTwo = (0 ..< 32).map(String.init).joined(separator: ";")
        #expect(parse("\u{1B}[\(thirtyTwo)m").count == 1)
        #expect(parse("\u{1B}[ !\"qx") == text("x"))
    }

    @Test func `a control inside a sequence is executed and the sequence goes on`() {
        #expect(
            parse("\u{1B}[1\n;2H")
                == [.execute(10), .csi(marker: 0, parameters: [1, 2], subMask: 0, intermediates: [], final: 0x48)]
        )
    }

    @Test func `ESC restarts, CAN and SUB cancel`() {
        #expect(
            parse("\u{1B}[1\u{1B}[2J") == [.csi(marker: 0, parameters: [2], subMask: 0, intermediates: [], final: 0x4A)]
        )
        #expect(parse("\u{1B}[1\u{18}x") == text("x"))
        #expect(parse("\u{1B}[1\u{1A}x") == text("x"))
    }

    @Test func `a parameter byte after an intermediate ignores the sequence`() {
        #expect(parse("\u{1B}[ 1mx") == text("x"))
        #expect(parse("\u{1B}[1?mx") == text("x"))
    }

    @Test func `OSC ends at BEL or ST and carries its bytes`() {
        let expected: [Event] = [
            .stringStart(.osc, header: [], marker: 0, intermediates: [], final: 0), .stringBytes(Array("0;title".utf8)),
            .stringEnd(completed: true)
        ]
        #expect(parse("\u{1B}]0;title\u{7}") == expected)
        #expect(parse("\u{1B}]0;title\u{1B}\\") == expected)
        #expect(parse("\u{1B}]0;title\u{1B}\\x") == expected + text("x"))
    }

    @Test func `an escape after an unfinished string ends it and starts the next sequence`() {
        #expect(
            parse("\u{1B}]0;a\u{1B}[H") == [
                .stringStart(.osc, header: [], marker: 0, intermediates: [], final: 0), .stringBytes(Array("0;a".utf8)),
                .stringEnd(completed: true),
                .csi(marker: 0, parameters: [], subMask: 0, intermediates: [], final: 0x48)
            ]
        )
    }

    @Test func `CAN cancels a string`() {
        #expect(
            parse("\u{1B}]0;a\u{18}x") == [
                .stringStart(.osc, header: [], marker: 0, intermediates: [], final: 0), .stringBytes(Array("0;a".utf8)),
                .stringEnd(completed: false)
            ] + text("x")
        )
    }

    @Test func `DCS reports its header, APC PM and SOS their kind`() {
        #expect(
            parse("\u{1B}P1;2$qm\u{1B}\\") == [
                .stringStart(.dcs, header: [1, 2], marker: 0, intermediates: [0x24], final: 0x71), .stringBytes([0x6D]),
                .stringEnd(completed: true)
            ]
        )
        #expect(
            parse("\u{1B}_Ga=T;AAAA\u{1B}\\") == [
                .stringStart(.apc, header: [], marker: 0, intermediates: [], final: 0),
                .stringBytes(Array("Ga=T;AAAA".utf8)),
                .stringEnd(completed: true)
            ]
        )
        #expect(
            parse("\u{1B}^x\u{1B}\\") == [
                .stringStart(.pm, header: [], marker: 0, intermediates: [], final: 0), .stringBytes([0x78]),
                .stringEnd(completed: true)
            ]
        )
        #expect(
            parse("\u{1B}Xx\u{1B}\\") == [
                .stringStart(.sos, header: [], marker: 0, intermediates: [], final: 0), .stringBytes([0x78]),
                .stringEnd(completed: true)
            ]
        )
    }

    @Test func `a string longer than the limit is cut and ends incomplete`() {
        let events = parse("\u{1B}]0;" + String(repeating: "a", count: 100) + "\u{7}x", maxStringLength: 10)
        #expect(
            events == [
                .stringStart(.osc, header: [], marker: 0, intermediates: [], final: 0),
                .stringBytes(Array("0;aaaaaaaa".utf8)),
                .stringEnd(completed: false)
            ] + text("x")
        )
    }

    @Test func `a string after a cut one starts with a clean count`() {
        let events = parse("\u{1B}]aaaaaaaaaaaa\u{7}\u{1B}]bb\u{7}", maxStringLength: 4)
        let start = Event.stringStart(.osc, header: [], marker: 0, intermediates: [], final: 0)
        #expect(
            events == [
                start, .stringBytes(Array("aaaa".utf8)), .stringEnd(completed: false), start,
                .stringBytes(Array("bb".utf8)), .stringEnd(completed: true)
            ]
        )
    }

    @Test func `C1 controls arriving as UTF-8 scalars act as controls`() {
        // U+009B is CSI, U+009C is ST, U+009D is OSC.
        #expect(
            parse("\u{9B}1;2H") == [.csi(marker: 0, parameters: [1, 2], subMask: 0, intermediates: [], final: 0x48)]
        )
        #expect(
            parse("\u{9D}0;t\u{9C}") == [
                .stringStart(.osc, header: [], marker: 0, intermediates: [], final: 0), .stringBytes(Array("0;t".utf8)),
                .stringEnd(completed: true)
            ]
        )
        #expect(parse("\u{85}") == [.execute(0x85)])
    }

    @Test func `a non-ASCII byte inside a sequence abandons it and is read afresh`() {
        #expect(parse("\u{1B}[1é") == text("é"))
    }
}
