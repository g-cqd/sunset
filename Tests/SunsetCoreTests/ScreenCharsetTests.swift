import Testing

@testable import SunsetCore

private let esc = "\u{1B}"

@Suite("Character sets") struct ScreenCharsetTests {
    @Test func `DEC special graphics draw lines`() {
        #expect(make("\(esc)(0lqqk\r\nx  x\r\nmqqj\(esc)(B", 4, 3).lines == ["┌──┐", "│  │", "└──┘"])
    }

    @Test func `only 0x5F to 0x7E are translated`() {
        #expect(make("\(esc)(0A1 q~_").lines[0] == "A1 ─·\u{A0}")
    }

    @Test func `designating ASCII again restores text`() {
        #expect(make("\(esc)(0q\(esc)(Bq").lines[0] == "─q")
    }

    @Test func `shift out selects G1 and shift in G0`() {
        #expect(make("\(esc))0\u{0E}q\u{0F}q").lines[0] == "─q")
        #expect(make("\(esc))0q\u{0E}q").lines[0] == "q─")
    }

    @Test func `the UK set has a pound sign`() {
        #expect(make("\(esc)(A#a").lines[0] == "£a")
    }

    @Test func `unknown designations are read as ASCII`() {
        #expect(make("\(esc)(Zq").lines[0] == "q")
    }

    @Test func `non-ASCII text is never translated`() {
        #expect(make("\(esc)(0é日").lines[0] == "é日")
    }

    @Test func `save and restore keep the character sets`() {
        #expect(make("\(esc)(0\(esc)7\(esc)(B\(esc)8q").lines[0] == "─")
    }

    @Test func `soft and full reset go back to ASCII`() {
        #expect(make("\(esc)(0\(esc)[!pq").lines[0] == "q")
        #expect(make("\(esc)(0\(esc)cq").lines[0] == "q")
    }

    @Test func `a run of ASCII is translated cell by cell across a wrap`() {
        #expect(make("\(esc)(0qqqqqqqqqqq", 5, 3).lines == ["─────", "─────", "─"])
    }
}
