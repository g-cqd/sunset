import Testing

@testable import SunsetCore

@Suite("Mouse") struct MouseEncoderTests {
    private func encode(
        _ event: MouseEvent,
        _ tracking: MouseTracking = .normal,
        _ format: MouseFormat = .sgr
    ) -> String? {
        MouseEncoder.encode(event, tracking: tracking, format: format).map { String(decoding: $0, as: UTF8.self) }
    }

    @Test func `SGR reports presses and releases with one-based cells, and the release keeps its button`() {
        #expect(encode(.init(.press, .left, column: 9, row: 19)) == "\u{1B}[<0;10;20M")
        #expect(encode(.init(.release, .left, column: 9, row: 19)) == "\u{1B}[<0;10;20m")
        #expect(encode(.init(.press, .middle, column: 0, row: 0)) == "\u{1B}[<1;1;1M")
        #expect(encode(.init(.press, .right, column: 0, row: 0)) == "\u{1B}[<2;1;1M")
    }

    @Test func `modifiers add 4 for shift, 8 for option and 16 for control`() {
        #expect(encode(.init(.press, .left, column: 0, row: 0, modifiers: [.shift, .control])) == "\u{1B}[<20;1;1M")
        #expect(encode(.init(.press, .left, column: 0, row: 0, modifiers: .option)) == "\u{1B}[<8;1;1M")
    }

    @Test func `the wheel is a press of button 64 to 67 and has no release`() {
        #expect(encode(.init(.press, .wheelUp, column: 1, row: 2)) == "\u{1B}[<64;2;3M")
        #expect(encode(.init(.press, .wheelDown, column: 1, row: 2)) == "\u{1B}[<65;2;3M")
        #expect(encode(.init(.press, .wheelLeft, column: 1, row: 2)) == "\u{1B}[<66;2;3M")
        #expect(encode(.init(.press, .wheelRight, column: 1, row: 2)) == "\u{1B}[<67;2;3M")
        #expect(encode(.init(.release, .wheelUp, column: 1, row: 2)) == nil)
    }

    @Test func `motion adds 32 and is reported only by the modes that ask for it`() {
        let drag = MouseEvent(.motion, .left, column: 4, row: 5)
        let hover = MouseEvent(.motion, .none, column: 4, row: 5)
        #expect(encode(drag, .normal) == nil)
        #expect(encode(drag, .button) == "\u{1B}[<32;5;6M")
        #expect(encode(hover, .button) == nil)
        #expect(encode(drag, .any) == "\u{1B}[<32;5;6M")
        #expect(encode(hover, .any) == "\u{1B}[<35;5;6M")
    }

    @Test func `the default format is bytes: 32 plus the one-based value, a release is button 3`() {
        #expect(
            MouseEncoder.encode(.init(.press, .left, column: 0, row: 0), tracking: .normal, format: .x10) == [
                0x1B, 0x5B, 0x4D, 0x20, 0x21, 0x21
            ]
        )
        #expect(
            MouseEncoder.encode(.init(.release, .right, column: 1, row: 2), tracking: .normal, format: .x10) == [
                0x1B, 0x5B, 0x4D, 0x23, 0x22, 0x23
            ]
        )
    }

    @Test func `the default format cannot say a column past 222, and the UTF-8 format can`() {
        let far = MouseEvent(.press, .left, column: 300, row: 0)
        #expect(MouseEncoder.encode(far, tracking: .normal, format: .x10) == nil)
        // 32 + 301 = 333 = U+014D, two bytes in UTF-8.
        #expect(
            MouseEncoder.encode(far, tracking: .normal, format: .utf8) == [0x1B, 0x5B, 0x4D, 0x20, 0xC5, 0x8D, 0x21]
        )
    }

    @Test func `URXVT sends decimal numbers with button plus 32, and a release is button 3`() {
        #expect(encode(.init(.press, .left, column: 0, row: 0), .normal, .urxvt) == "\u{1B}[32;1;1M")
        #expect(encode(.init(.release, .left, column: 4, row: 9), .normal, .urxvt) == "\u{1B}[35;5;10M")
    }

    @Test func `the pixel format sends pixel positions`() {
        let event = MouseEvent(.press, .left, column: 3, row: 1, pixelX: 30, pixelY: 20)
        #expect(encode(event, .normal, .sgrPixels) == "\u{1B}[<0;31;21M")
    }

    @Test func `tracking off reports nothing; X10 reports presses only, with no modifiers`() {
        #expect(encode(.init(.press, .left, column: 0, row: 0), .none) == nil)
        #expect(encode(.init(.release, .left, column: 0, row: 0), .x10) == nil)
        #expect(encode(.init(.press, .left, column: 0, row: 0, modifiers: .control), .x10, .x10) == "\u{1B}[M !!")
    }
}
