import Testing

@testable import SunsetCore

func run(_ input: String) -> (Screen, String) {
    var terminal = Terminal(columns: 10, rows: 4)
    terminal.feed(input)
    let replies = String(decoding: terminal.takeReplies(), as: UTF8.self)
    return (terminal.screen, replies)
}

@Suite("OSC: titles") struct OSCTitleTests {
    @Test func `0 sets title and icon, 2 the title, 1 the icon`() {
        var (screen, _) = run("\(esc)]0;hello\(bel)")
        #expect(screen.title == "hello")
        #expect(screen.iconName == "hello")
        (screen, _) = run("\(esc)]2;t\(st)")
        #expect(screen.title == "t")
        #expect(screen.iconName == "")
        (screen, _) = run("\(esc)]1;i\(bel)")
        #expect(screen.title == "")
        #expect(screen.iconName == "i")
    }

    @Test func `controls are removed from titles and Unicode is kept`() {
        #expect(run("\(esc)]2;a\u{1}b\u{7F}c\(bel)").0.title == "abc")
        #expect(run("\(esc)]2;日本\u{85}語\(bel)").0.title == "日本語")
        #expect(run("\(esc)]2;\(bel)").0.title == "")
    }

    @Test func `a title is never reported back`() {
        #expect(run("\(esc)]2;secret\(bel)\(esc)[21t\(esc)[20t").1 == "")
    }

    @Test func `an over-long OSC is dropped whole and the next one works`() {
        var terminal = Terminal(columns: 10, rows: 4)
        terminal.feed("\(esc)]2;keep\(bel)")
        terminal.feed("\(esc)]2;" + String(repeating: "x", count: 5000) + bel)
        #expect(terminal.screen.title == "keep")
        terminal.feed("\(esc)]2;next\(bel)")
        #expect(terminal.screen.title == "next")
    }

    @Test func `other strings are not read as OSC`() {
        let (screen, replies) = run(
            "\(esc)_2;apc\(st)\(esc)P2;dcs\(st)\(esc)^2;pm\(st)\(esc)X2;sos\(st)\(esc)_4;1;?\(st)"
        )
        #expect(screen.title == "")
        #expect(replies == "")
    }

    @Test func `a cancelled OSC does nothing`() {
        #expect(run("\(esc)]2;gone\u{18}").0.title == "")
    }

    @Test func `the title stack saves and restores`() {
        var terminal = Terminal(columns: 10, rows: 4)
        terminal.feed("\(esc)]2;one\(bel)\(esc)[22;2t\(esc)]2;two\(bel)")
        #expect(terminal.screen.title == "two")
        terminal.feed("\(esc)[23;2t")
        #expect(terminal.screen.title == "one")
        terminal.feed("\(esc)[23;2t")
        #expect(terminal.screen.title == "one", "popping an empty stack changes nothing")
    }

    @Test func `the title stack is bounded`() {
        var terminal = Terminal(columns: 10, rows: 4)
        for index in 0 ..< 30 { terminal.feed("\(esc)]2;t\(index)\(bel)\(esc)[22;2t") }
        for _ in 0 ..< 30 { terminal.feed("\(esc)[23;2t") }
        #expect(terminal.screen.title == "t20", "ten are kept: the oldest of the thirty were dropped")
    }
}
