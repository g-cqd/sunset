import Foundation
import Testing

@testable import SunsetCore

/// DECFRA, DECERA and DECCRA as esctest2 (Thomas Dickey's, the suite xterm is checked against; read 2026-11-26) expects:
/// its cases' setups and expected screens, restated here (no code copied). Sunset has no left/right margins (DECSLRM),
/// so the cases' column margins do not apply; their top/bottom margins and origin mode do.
@Suite("VT400 rectangles, as esctest2 expects") struct VTRectangleConformanceTests {
    private static let data = [
        "abcdefgh", "ijklmnop", "qrstuvwx", "yz012345", "ABCDEFGH", "IJKLMNOP", "QRSTUVWX", "YZ6789!@"
    ]

    /// A 12×10 screen with `data` in its top-left corner, as the cases' `prepare` writes it.
    private func prepared() -> Terminal {
        var t = Terminal(columns: 12, rows: 10)
        t.feed("\(esc)[H" + Self.data.joined(separator: "\r\n") + "\r\n")
        return t
    }

    /// The top-left 8×8 corner; blanks as spaces.
    private func corner(_ t: Terminal) -> [String] {
        (0 ..< 8)
            .map { row in String(t.screen.text(row: row).padding(toLength: 8, withPad: " ", startingAt: 0).prefix(8)) }
    }

    private func replaced(_ rows: ClosedRange<Int>, _ columns: ClosedRange<Int>, with character: Character) -> [String]
    {
        Self.data.enumerated()
            .map { row, line in
                String(
                    line.enumerated()
                        .map { rows.contains(row + 1) && columns.contains($0.offset + 1) ? character : $0.element }
                )
            }
    }

    // MARK: - DECFRA (`CSI Pc ; Pt ; Pl ; Pb ; Pr $ x`) and DECERA (`CSI Pt ; Pl ; Pb ; Pr $ z`)

    /// DECFRA with `%` (37), or DECERA, over `rect` (1-based, as written).
    private func fill(_ t: inout Terminal, _ rect: String, erase: Bool) {
        t.feed(erase ? "\(esc)[\(rect)$z" : "\(esc)[37;\(rect)$x")
    }

    @Test(arguments: [false, true])
    func `basic, inverted, and margins ignored without origin mode`(erase: Bool) {
        let mark: Character = erase ? " " : "%"
        var t = prepared()
        fill(&t, "5;5;7;7", erase: erase)
        #expect(corner(t) == replaced(5 ... 7, 5 ... 7, with: mark))

        var inverted = prepared()
        fill(&inverted, "5;5;4;4", erase: erase)
        #expect(corner(inverted) == Self.data, "an inverted rectangle does nothing")

        var margins = prepared()
        margins.feed("\(esc)[3;6r")
        fill(&margins, "5;5;7;7", erase: erase)
        margins.feed("\(esc)[r")
        #expect(corner(margins) == replaced(5 ... 7, 5 ... 7, with: mark), "margins do not clip without origin mode")
    }

    @Test(arguments: [false, true])
    func `origin mode counts from the top margin`(erase: Bool) {
        var t = prepared()
        t.feed("\(esc)[2;9r\(esc)[?6h")
        fill(&t, "1;1;3;3", erase: erase)
        t.feed("\(esc)[?6l\(esc)[r")
        #expect(corner(t) == replaced(2 ... 4, 1 ... 3, with: erase ? " " : "%"))
    }

    @Test(arguments: [false, true])
    func `no arguments is the whole screen; too large is clipped; the cursor stays`(erase: Bool) {
        var t = Terminal(columns: 12, rows: 10)
        t.feed("\(esc)[1;1H1\(esc)[1;12H2\(esc)[10;12H3\(esc)[10;1H4\(esc)[5;5H")
        t.feed(erase ? "\(esc)[$z" : "\(esc)[37$x")
        let mark = erase ? " " : "%"
        for (row, column) in [(0, 0), (0, 11), (9, 11), (9, 0)] {
            let line = t.screen.text(row: row).padding(toLength: 12, withPad: " ", startingAt: 0)
            #expect(String(Array(line)[column]) == mark, "corner \(row),\(column)")
        }
        #expect(t.screen.cursorRow == 4 && t.screen.cursorColumn == 4)

        var large = Terminal(columns: 12, rows: 10)
        large.feed("\(esc)[9;11Hab\(esc)[10;11Hcd")
        fill(&large, "10;12;20;22", erase: erase)
        #expect(large.screen.text(row: 8).hasSuffix("ab"))
        #expect(large.screen.text(row: 9).padding(toLength: 12, withPad: " ", startingAt: 0).hasSuffix("c" + mark))
    }

    // MARK: - DECCRA (`CSI Pts ; Pls ; Pbs ; Prs ; Pps ; Ptd ; Pld ; Ppd $ v`)

    @Test func `copies, through a buffer when source and destination overlap`() {
        var t = prepared()
        t.feed("\(esc)[2;2;4;4;1;5;5;1$v")
        #expect(
            corner(t) == [
                "abcdefgh", "ijklmnop", "qrstuvwx", "yz012345", "ABCDjklH", "IJKLrstP", "QRSTz01X", "YZ6789!@"
            ]
        )
        var overlapping = prepared()
        overlapping.feed("\(esc)[2;2;4;4;1;3;3;1$v")
        #expect(
            corner(overlapping)
                == ["abcdefgh", "ijklmnop", "qrjklvwx", "yzrst345", "ABz01FGH", "IJKLMNOP", "QRSTUVWX", "YZ6789!@"]
        )
    }

    @Test func `defaults: source from the top-left, destination at the top-left`() {
        var source = prepared()
        source.feed("\(esc)[;;2;2;1;5;5;1$v")
        #expect(corner(source)[4] == "ABCDabGH" && corner(source)[5] == "IJKLijOP")
        var destination = prepared()
        destination.feed("\(esc)[2;2;4;4;1$v")
        #expect(corner(destination).prefix(3) == ["jkldefgh", "rstlmnop", "z01tuvwx"])
    }

    @Test func `an inverted source does nothing; a large source and an offscreen destination are clipped`() {
        var inverted = prepared()
        inverted.feed("\(esc)[2;2;1;1;1;5;5;1$v")
        #expect(corner(inverted) == Self.data)

        var offscreen = prepared()
        offscreen.feed("\(esc)[2;2;4;4;1;9;11;1$v")
        #expect(offscreen.screen.text(row: 8).hasSuffix("jk") && offscreen.screen.text(row: 9).hasSuffix("rs"))

        var large = Terminal(columns: 12, rows: 10)
        large.feed("\(esc)[9;11Hab\(esc)[10;11HcX\(esc)[10;12;11;13;1;9;11;1$v")
        #expect(large.screen.text(row: 8).hasSuffix("Xb") && large.screen.text(row: 9).hasSuffix("cX"))
    }

    @Test func `origin mode counts both rectangles from the top margin, and the cursor stays`() {
        var t = prepared()
        t.feed("\(esc)[2;9r\(esc)[?6h\(esc)[3;3H")
        t.feed("\(esc)[1;1;3;3;1;4;4;1$v")
        let cursor = (t.screen.cursorRow, t.screen.cursorColumn)
        t.feed("\(esc)[?6l\(esc)[r")
        #expect(cursor == (3, 2), "the cursor did not move")
        // Source rows 2-4, columns 1-3 ("ijk", "qrs", "yz0") to rows 5-7, column 4.
        #expect(corner(t)[4 ... 6] == ["ABCijkGH", "IJKqrsOP", "QRSyz0WX"])
    }
}
