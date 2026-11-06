import SunsetCore
import Testing

@testable import SunsetRender

@Suite("CPU renderer: scrolled back") struct CPURendererViewportTests {
    /// Six lines, each with its own background (palette colour 1 to 6), on a screen of 4 rows: lines 1 and 2 are in the history.
    private static let lines = (1 ... 6).map { "\u{1B}[48;5;\($0)m \u{1B}[K" }.joined(separator: "\r\n")

    private func background(_ line: Int) -> RGB { Palette().colors[line] }

    @Test func `scrolled back, the top rows show the history and the rest the screen`() {
        var rig = CPURendererRig()
        rig.frame(Self.lines, cursorVisible: false, scrolledBack: 2)
        for row in 0 ..< 4 {
            #expect(rig.pixel(row: row, column: 5, x: 3, y: 5) == background(row + 1), "row \(row)")
        }
        rig.frame(cursorVisible: false, scrolledBack: 1)
        for row in 0 ..< 4 {
            #expect(rig.pixel(row: row, column: 5, x: 3, y: 5) == background(row + 2), "row \(row)")
        }
    }

    @Test func `going back to the live screen draws it again`() {
        var rig = CPURendererRig()
        rig.frame(Self.lines, cursorVisible: false, scrolledBack: 2)
        rig.frame(cursorVisible: false, scrolledBack: 0)
        for row in 0 ..< 4 {
            #expect(rig.pixel(row: row, column: 5, x: 3, y: 5) == background(row + 3), "row \(row)")
        }
    }

    @Test func `the cursor is not drawn while scrolled back`() {
        var rig = CPURendererRig()
        rig.frame("\u{1B}[1;1H", cursorVisible: true)
        #expect(rig.pixel(row: 0, column: 0, x: 3, y: 5) != black, "the block cursor is there")
        rig.frame(cursorVisible: true, scrolledBack: 0)
        let live = rig.surface
        rig.terminal.feed(Self.lines)
        rig.frame(cursorVisible: true, scrolledBack: 1)
        for row in 0 ..< 4 { #expect(rig.pixel(row: row, column: 0, x: 3, y: 5) == background(row + 2)) }
        #expect(live.pixels != rig.surface.pixels)
    }

    @Test func `a frame scrolled back is what a fresh renderer draws`() {
        var rig = CPURendererRig()
        rig.frame(Self.lines, scrolledBack: 2)
        rig.frame("\u{1B}[3;3Hxy", scrolledBack: 2)
        var fresh = Surface(width: rig.surface.width, height: rig.surface.height)
        CPURenderer(metrics: metrics, glyphs: BoxGlyphSource())
            .render(rig.terminal.screen, into: &fresh, scrolledBack: 2)
        #expect(fresh.pixels == rig.surface.pixels)
    }
}
