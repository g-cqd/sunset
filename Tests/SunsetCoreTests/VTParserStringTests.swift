import Testing

@testable import SunsetCore

@Suite("VT parser strings") struct VTParserStringTests {
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

    @Test func `a string reports how it ended`() {
        func endings(_ text: String) -> [StringTerminator] {
            var parser = VTParser()
            var sink = Recorder()
            var bytes = text
            bytes.withUTF8 { parser.parse($0.span, into: &sink) }
            return sink.endings
        }
        #expect(endings("\u{1B}]0;a\u{7}") == [.bel])
        #expect(endings("\u{1B}]0;a\u{1B}\\") == [.st])
        #expect(endings("\u{9D}0;a\u{9C}") == [.st])
        #expect(endings("\u{1B}]0;a\u{1B}[H") == [.st])
        #expect(endings("\u{1B}]0;a\u{18}") == [.none])
        #expect(endings("\u{1B}P1qa\u{7}\u{1B}\\") == [.st], "BEL is content inside a DCS, not a terminator")
    }
}
