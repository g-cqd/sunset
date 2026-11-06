import SunsetCore
import Testing

@testable import SunsetRender

@Suite("CPU renderer: selection") struct CPURendererSelectionTests {
    private func point(_ line: Int, _ column: Int) -> SelectionPoint { SelectionPoint(line: line, column: column) }

    @Test func `selected cells are drawn with their colours swapped`() {
        var rig = CPURendererRig()
        rig.frame("\u{1B}[31;44mabc", cursorVisible: false)
        #expect(rig.pixel(row: 0, column: 1, x: 0, y: 0) == RGB(0, 0, 238), "the background before")
        rig.frame(cursorVisible: false, selection: Selection(anchor: point(0, 1), head: point(0, 2)))
        #expect(
            rig.pixel(row: 0, column: 1, x: 0, y: 0) == RGB(205, 0, 0),
            "the background is now the foreground colour"
        )
        #expect(rig.pixel(row: 0, column: 1, x: 3, y: 5) == RGB(0, 0, 238), "and the glyph the background colour")
        #expect(rig.pixel(row: 0, column: 0, x: 0, y: 0) == RGB(0, 0, 238), "cells outside are as they were")
        #expect(rig.pixel(row: 0, column: 3, x: 0, y: 0) == black)
    }

    @Test func `a selection that is cleared leaves the cells as they were`() {
        var rig = CPURendererRig()
        rig.frame("\u{1B}[31;44mabc", cursorVisible: false)
        let before = rig.surface
        rig.frame(cursorVisible: false, selection: Selection(anchor: point(0, 0), head: point(0, 2)))
        #expect(rig.surface.pixels != before.pixels)
        rig.frame(cursorVisible: false, selection: nil)
        #expect(rig.surface.pixels == before.pixels)
    }

    @Test func `a selection that runs over several lines marks the cells in between`() {
        var rig = CPURendererRig()
        rig.frame("a\r\nb\r\nc\r\nd", cursorVisible: false)
        rig.frame(cursorVisible: false, selection: Selection(anchor: point(0, 5), head: point(2, 1)))
        #expect(rig.pixel(row: 0, column: 4, x: 0, y: 0) == black)
        #expect(rig.pixel(row: 0, column: 5, x: 0, y: 0) == white)
        #expect(rig.pixel(row: 1, column: 9, x: 0, y: 0) == white)
        #expect(rig.pixel(row: 2, column: 1, x: 0, y: 0) == white)
        #expect(rig.pixel(row: 2, column: 2, x: 0, y: 0) == black)
        #expect(rig.pixel(row: 3, column: 0, x: 0, y: 0) == black)
    }

    @Test func `a selection in the history is shown where the window is scrolled over it`() {
        var rig = CPURendererRig()
        rig.frame("1\r\n2\r\n3\r\n4\r\n5\r\n6", cursorVisible: false, scrolledBack: 2)
        rig.frame(
            cursorVisible: false,
            scrolledBack: 2,
            selection: Selection(anchor: point(0, 0), head: point(0, 9))
        )
        #expect(rig.pixel(row: 0, column: 5, x: 0, y: 0) == white, "line 0 of the history is the top row of the window")
        #expect(rig.pixel(row: 1, column: 5, x: 0, y: 0) == black)
        rig.frame(cursorVisible: false, scrolledBack: 0, selection: Selection(anchor: point(0, 0), head: point(0, 9)))
        for row in 0 ..< 4 {
            #expect(rig.pixel(row: row, column: 5, x: 0, y: 0) == black, "off the window: row \(row)")
        }
    }

    @Test func `changing the selection step by step draws what a fresh renderer draws`() {
        var rig = CPURendererRig()
        rig.frame("\u{1B}[32mhello\r\nworld\r\n\u{1B}[41mred", cursorVisible: false)
        let steps = [
            Selection(anchor: point(0, 1), head: point(0, 3)),
            Selection(anchor: point(0, 1), head: point(2, 1)),
            Selection(anchor: point(1, 2), head: point(1, 4), shape: .block),
            Selection(anchor: point(2, 0), head: point(0, 0))
        ]
        for selection in steps {
            rig.frame(cursorVisible: false, selection: selection)
            var fresh = Surface(width: rig.surface.width, height: rig.surface.height)
            CPURenderer(metrics: metrics, glyphs: BoxGlyphSource())
                .render(rig.terminal.screen, into: &fresh, cursorVisible: false, selection: selection)
            #expect(fresh.pixels == rig.surface.pixels, "\(selection)")
        }
    }
}
