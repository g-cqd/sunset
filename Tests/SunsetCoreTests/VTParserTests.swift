import Testing

@testable import SunsetCore

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
        let r: Unicode.Scalar = "\u{FFFD}"
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
}
