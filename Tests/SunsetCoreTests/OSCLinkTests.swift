import Testing

@testable import SunsetCore

@Suite("OSC 8 hyperlinks (ADR-0010)") struct OSCLinkTests {
    private func feed(_ text: String, columns: Int = 40, rows: Int = 4, limit: Int = 100) -> Terminal {
        var t = Terminal(columns: columns, rows: rows, scrollbackLimit: limit)
        t.feed(text)
        return t
    }

    private func links(_ t: Terminal, count: Int) -> [String?] {
        (0 ..< count).map { t.screen.link(row: 0, column: $0) }
    }

    @Test func `text between the start and the end of a link belongs to it`() {
        let t = feed("\(esc)]8;;http://a.example/x\u{07}ab\(esc)]8;;\u{07}c")
        #expect(links(t, count: 4) == ["http://a.example/x", "http://a.example/x", nil, nil])
    }

    @Test func `the string terminator works as well as BEL`() {
        let t = feed("\(esc)]8;;http://a.example\(esc)\\ab\(esc)]8;;\(esc)\\c")
        #expect(links(t, count: 3) == ["http://a.example", "http://a.example", nil])
    }

    @Test func `a link survives colour changes and resets of the pen`() {
        let t = feed("\(esc)]8;;http://x.example\u{07}a\(esc)[31mb\(esc)[0mc\(esc)[1;4md")
        #expect(links(t, count: 4).allSatisfy { $0 == "http://x.example" })
    }

    @Test func `parameters are accepted and ignored`() {
        let t = feed("\(esc)]8;id=7:foo=bar;http://x.example\u{07}a")
        #expect(links(t, count: 1) == ["http://x.example"])
    }

    @Test func `a new link replaces the one before it`() {
        let t = feed("\(esc)]8;;http://one.example\u{07}a\(esc)]8;;http://two.example\u{07}b")
        #expect(links(t, count: 2) == ["http://one.example", "http://two.example"])
    }

    @Test func `erased cells and blank cells made by erasing carry no link`() {
        let t = feed("\(esc)]8;;http://x.example\u{07}abc\(esc)[1;1H\(esc)[2K")
        #expect(links(t, count: 3) == [nil, nil, nil])
    }

    @Test func `a link is kept when its line scrolls into the history`() {
        let t = feed("\(esc)]8;;http://x.example\u{07}first\(esc)]8;;\u{07}\r\n2\r\n3\r\n4\r\n5", columns: 10)
        #expect(t.screen.scrollbackCount >= 1)
        #expect(t.screen.viewportLink(row: 0, column: 0, scrolledBack: t.screen.scrollbackCount) == "http://x.example")
        #expect(t.screen.viewportLink(row: 0, column: 9, scrolledBack: t.screen.scrollbackCount) == nil)
    }

    @Test
    func
        `an address with a control character, bad UTF-8 or more than 2083 bytes is not a link, and ends the one before`()
    {
        let ok = "\(esc)]8;;http://ok.example\u{07}"
        #expect(links(feed(ok + "\(esc)]8;;http://a\u{7F}b\u{07}x"), count: 1) == [nil])
        #expect(links(feed(ok + "\(esc)]8;;http://\(String(repeating: "a", count: 2100))\u{07}x"), count: 1) == [nil])
        let exact = "http://" + String(repeating: "a", count: 2083 - 7)
        #expect(links(feed("\(esc)]8;;\(exact)\u{07}x"), count: 1) == [exact])
    }

    @Test func `no more than 65535 distinct links are kept, and the rest are text`() {
        var t = Terminal(columns: 80, rows: 4, scrollbackLimit: 0)
        for index in 0 ..< 66000 { t.feed("\(esc)]8;;http://h/\(index)\u{07}x\r\n") }
        t.feed("\(esc)]8;;http://h/0\u{07}y")
        #expect(t.screen.link(row: 3, column: 0) == "http://h/0", "a link already known is still usable")
        t.feed("\r\(esc)]8;;http://h/new\u{07}z")
        #expect(t.screen.link(row: 3, column: 0) == nil, "a new one past the limit is not recorded")
    }

    @Test func `a link is not reported back`() {
        var t = feed("\(esc)]8;;http://x.example\u{07}a\(esc)]8;;?\u{07}")
        #expect(t.takeReplies().isEmpty)
    }

    @Test func `only web, mail and ssh links, and local files, may be opened`() {
        func opens(_ address: String) -> Bool { HyperlinkPolicy.opens(address, localHost: "mac.local") }
        #expect(opens("http://example.com") && opens("https://example.com/a?b=c") && opens("HTTPS://EXAMPLE.COM"))
        #expect(opens("mailto:me@example.com") && opens("ssh://host/path"))
        #expect(opens("file:///Users/me/a.txt") && opens("file://mac.local/Users/me") && opens("file://localhost/tmp"))
        #expect(!opens("file://other.host/etc/passwd"))
        #expect(
            !opens("javascript:alert(1)") && !opens("data:text/html,hi") && !opens("x-apple.systempreferences:")
                && !opens("/just/a/path")
        )
        #expect(!opens("") && !opens("http:") && !opens("https//no.colon"))
    }
}
