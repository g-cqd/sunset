import Testing

@testable import SunsetCore

/// OSC 22: the program chooses the shape of the mouse pointer over its screen (xterm's form, and kitty's stack and queries).
@Suite("OSC 22 pointer shape") struct OSCPointerTests {
    private func feed(_ text: String) -> Terminal {
        var t = Terminal(columns: 20, rows: 4, scrollbackLimit: 10)
        t.feed(text)
        return t
    }

    private func replies(_ t: inout Terminal) -> String { String(decoding: t.takeReplies(), as: UTF8.self) }

    @Test func `a name sets the shape, with or without the equals sign, and an empty one gives the default back`() {
        #expect(feed("").screen.pointerShape == nil)
        #expect(feed("\(esc)]22;pointer\u{07}").screen.pointerShape == .pointer)
        #expect(feed("\(esc)]22;=crosshair\(esc)\\").screen.pointerShape == .crosshair)
        #expect(feed("\(esc)]22;pointer\u{07}\(esc)]22;\u{07}").screen.pointerShape == nil)
        let unknown = feed("\(esc)]22;pointer\u{07}\(esc)]22;no-such-shape\u{07}")
        #expect(unknown.screen.pointerShape == .pointer, "an unknown name changes nothing")
    }

    @Test func `shapes are pushed and popped, setting replaces the top, and the stack is bounded`() {
        var t = feed("\(esc)]22;>text\u{07}\(esc)]22;>wait,help\u{07}")
        #expect(t.screen.pointerShape == .help)
        t.feed("\(esc)]22;=move\u{07}\(esc)]22;<\u{07}")
        #expect(t.screen.pointerShape == .wait, "set replaced help, pop took it off")
        t.feed("\(esc)]22;<\u{07}\(esc)]22;<\u{07}\(esc)]22;<\u{07}")
        #expect(t.screen.pointerShape == nil, "popping an empty stack is nothing")
        for _ in 0 ..< 40 { t.feed("\(esc)]22;>grab\u{07}") }
        t.feed("\(esc)]22;>pointer\u{07}")
        for _ in 0 ..< PointerState.limit - 1 { t.feed("\(esc)]22;<\u{07}") }
        #expect(t.screen.pointerShape == .grab, "the oldest were dropped, not the newest")
        t.feed("\(esc)]22;<\u{07}")
        #expect(t.screen.pointerShape == nil)
    }

    @Test func `a query says which names are known and names the current shape, ended as it was asked`() {
        var t = feed("\(esc)]22;?pointer,bogus,text\u{07}")
        #expect(replies(&t) == "\(esc)]22;1,0,1\u{07}")
        t.feed("\(esc)]22;wait\u{07}\(esc)]22;?__current__,__default__\(esc)\\")
        #expect(replies(&t) == "\(esc)]22;wait,default\(esc)\\")
    }

    @Test func `the alternate screen has a stack of its own, and a reset forgets both`() {
        var t = feed("\(esc)]22;pointer\u{07}\(esc)[?1049h")
        #expect(t.screen.pointerShape == nil)
        t.feed("\(esc)]22;crosshair\u{07}\(esc)[?1049l")
        #expect(t.screen.pointerShape == .pointer)
        t.feed("\(esc)c")
        #expect(t.screen.pointerShape == nil)
    }
}
