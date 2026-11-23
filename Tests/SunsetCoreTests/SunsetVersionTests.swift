import Testing

@testable import SunsetCore

/// What says a program may draw with placeholders: XTVERSION reports the version that has them.
@Suite("the version programs read") struct SunsetVersionTests {
    @Test func `XTVERSION reports Sunset's version, the one with Unicode placeholders`() {
        var t = Terminal(columns: 10, rows: 2)
        t.feed("\u{1B}[>q")
        #expect(String(decoding: t.takeReplies(), as: UTF8.self) == "\u{1B}P>|sunset(0.1.0)\u{1B}\\")
        #expect("\(Sunset.version)" == "0.1.0")
    }
}
