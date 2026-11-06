import Testing

@testable import SunsetCore

@Suite("OSC 52 clipboard (ADR-0010)") struct OSCClipboardTests {
    private func events(_ text: String, columns: Int = 20) -> [HostEvent] {
        var t = Terminal(columns: columns, rows: 4)
        t.feed(text)
        return t.takeEvents()
    }

    @Test func `a write puts the decoded text on the clipboard`() {
        #expect(events("\(esc)]52;c;aGVsbG8=\u{07}") == [.clipboardWrite("hello")])
        #expect(events("\(esc)]52;c;aGVsbG8=\(esc)\\") == [.clipboardWrite("hello")])
    }

    @Test func `an empty target, and the primary and selection targets, mean the one pasteboard`() {
        #expect(events("\(esc)]52;;aGk=\u{07}") == [.clipboardWrite("hi")])
        #expect(events("\(esc)]52;p;aGk=\u{07}") == [.clipboardWrite("hi")])
        #expect(events("\(esc)]52;s;aGk=\u{07}") == [.clipboardWrite("hi")])
        #expect(events("\(esc)]52;pc;aGk=\u{07}") == [.clipboardWrite("hi")])
    }

    @Test func `cut buffers and unknown targets are ignored`() {
        #expect(events("\(esc)]52;0;aGk=\u{07}").isEmpty)
        #expect(events("\(esc)]52;x;aGk=\u{07}").isEmpty)
    }

    @Test func `a read is denied and gets no reply at all`() {
        var t = Terminal(columns: 20, rows: 4)
        t.feed("\(esc)]52;c;?\u{07}")
        #expect(t.takeEvents().isEmpty)
        #expect(t.takeReplies().isEmpty)
    }

    @Test func `bad base64, bad UTF-8 and empty data are dropped whole`() {
        #expect(events("\(esc)]52;c;***\u{07}").isEmpty)
        #expect(events("\(esc)]52;c;aGVsbG8\u{07}").isEmpty, "unpadded")
        #expect(events("\(esc)]52;c;/w==\u{07}").isEmpty, "0xFF is not UTF-8")
        #expect(events("\(esc)]52;c;\u{07}").isEmpty, "a program cannot clear the clipboard")
    }

    @Test func `a payload far beyond the usual OSC limit is accepted up to 1 MiB of base64`() {
        let text = String(repeating: "a", count: 300_000)
        let encoded = String(repeating: "YWFh", count: 100_000)  // 300 000 bytes
        #expect(events("\(esc)]52;c;\(encoded)\u{07}") == [.clipboardWrite(text)])
        let tooBig = String(repeating: "YWFh", count: 280_000)  // 1 120 000 characters
        #expect(events("\(esc)]52;c;\(tooBig)\u{07}").isEmpty)
    }

    @Test func `other codes keep the small limit`() {
        let long = String(repeating: "x", count: 5000)
        var t = Terminal(columns: 20, rows: 4)
        t.feed("\(esc)]2;\(long)\u{07}")
        #expect(t.screen.title.isEmpty)
    }

    @Test func `the buffer for a big payload is let go afterwards`() {
        var t = Terminal(columns: 20, rows: 4)
        t.feed("\(esc)]52;c;\(String(repeating: "YWFh", count: 100_000))\u{07}")
        t.feed("\(esc)]2;t\u{07}")
        #expect(t.screen.oscBuffer.capacity < 100_000)
    }

    @Test func `a flood of writes keeps the newest 64 events`() {
        var t = Terminal(columns: 20, rows: 4)
        for index in 0 ..< 100 {
            t.feed("\(esc)]52;c;\(Base64Fixture.encode("n\(index)"))\u{07}")
        }
        let taken = t.takeEvents()
        #expect(taken.count == 64)
        #expect(taken.last == .clipboardWrite("n99") && taken.first == .clipboardWrite("n36"))
        #expect(t.takeEvents().isEmpty, "taken once")
    }
}
