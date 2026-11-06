import Testing

@testable import SunsetCore

@Suite("Screen: cursor movement") struct ScreenCursorTests {
    @Test func `CUP CUU CUD CUF CUB move and clamp`() {
        #expect(make("\(esc)[3;5H").cursor == [2, 4])
        #expect(make("\(esc)[H").cursor == [0, 0])
        #expect(make("\(esc)[99;99H").cursor == [3, 9])
        #expect(make("\(esc)[3;3H\(esc)[A").cursor == [1, 2])
        #expect(make("\(esc)[3;3H\(esc)[2B").cursor == [4 - 1, 2])
        #expect(make("\(esc)[3;3H\(esc)[C").cursor == [2, 3])
        #expect(make("\(esc)[3;3H\(esc)[2D").cursor == [2, 0])
        #expect(make("\(esc)[3;3H\(esc)[99A").cursor == [0, 2])
    }

    @Test func `CHA VPA CNL CPL HPA`() {
        #expect(make("\(esc)[3;3H\(esc)[7G").cursor == [2, 6])
        #expect(make("\(esc)[3;3H\(esc)[1d").cursor == [0, 2])
        #expect(make("\(esc)[2;3H\(esc)[E").cursor == [2, 0])
        #expect(make("\(esc)[3;3H\(esc)[F").cursor == [1, 0])
        #expect(make("\(esc)[3;3H\(esc)[5`").cursor == [2, 4])
    }

    @Test func `moving the cursor clears a pending wrap`() {
        #expect(make("0123456789\(esc)[DX").lines == ["01234567X9", "", "", ""])
    }

    @Test func `save and restore the cursor`() {
        let h = make("\(esc)[2;3H\(esc)7\(esc)[H\(esc)8X")
        #expect(h.lines == ["", "  X", "", ""])
        #expect(make("\(esc)[2;3H\(esc)[s\(esc)[H\(esc)[uX").lines == ["", "  X", "", ""])
    }

    @Test func `tabs: default stops, set, clear, forward and back`() {
        #expect(make("\t").cursor == [0, 8])
        #expect(make("\t\t").cursor == [0, 9])
        #expect(make("\(esc)[3G\(esc)H\r\t").cursor == [0, 2])
        #expect(make("\(esc)[3G\(esc)H\(esc)[g\r\t").cursor == [0, 8])
        #expect(make("\(esc)[3g\t").cursor == [0, 9])
        #expect(make("\(esc)[2I").cursor == [0, 9])
        #expect(make("\(esc)[10G\(esc)[Z").cursor == [0, 8])
    }

    @Test
    func
        `a back-tab, backspace or cursor-left that moves the cursor clears the pending wrap, so the next character lands where the cursor is`()
    {
        // Ten columns, text in the last one (wrap pending), then the cursor moves back: what is typed next goes at the new cursor, not on the next line (ghostty wraps it, which no one wants).
        #expect(make("0123456789\(esc)[ZX").lines == ["01234567X9", "", "", ""])
        #expect(make("0123456789\u{08}X").lines == ["01234567X9", "", "", ""])
        #expect(make("0123456789\(esc)[2DX").lines == ["0123456X89", "", "", ""])
    }

    @Test func `IND NEL RI`() {
        #expect(make("ab\(esc)Dc").lines == ["ab", "  c", "", ""])
        #expect(make("ab\(esc)Ec").lines == ["ab", "c", "", ""])
        #expect(make("ab\(esc)[2;1H\(esc)Mc").lines == ["cb", "", "", ""])
    }
}
