import Testing

@testable import SunsetCore

@Suite("Selection gesture") struct SelectionGestureTests {
    private func point(_ line: Int, _ column: Int) -> SelectionPoint { SelectionPoint(line: line, column: column) }

    private func gesture(_ granularity: SelectionGesture.Granularity, at start: SelectionPoint, _ t: Terminal)
        -> SelectionGesture
    {
        SelectionGesture(at: start, granularity: granularity, screen: t.screen)
    }

    @Test func `a click by cells selects nothing until the pointer moves to another cell`() {
        let t = terminal("hello world", 20)
        let click = gesture(.cells, at: point(0, 3), t)
        #expect(click.selection == nil)
        #expect(click.dragged(to: point(0, 3), screen: t.screen) == nil)
        #expect(click.dragged(to: point(0, 5), screen: t.screen) == Selection(anchor: point(0, 3), head: point(0, 5)))
    }

    @Test func `dragging back before the press selects backwards`() {
        let t = terminal("hello world", 20)
        let click = gesture(.cells, at: point(0, 6), t)
        let selection = click.dragged(to: point(0, 2), screen: t.screen)
        #expect(selection.map { t.screen.text(of: $0) } == "llo w")
    }

    @Test func `a double click selects the word and dragging widens it by words`() {
        let t = terminal("alpha beta gamma", 20)
        let click = gesture(.words, at: point(0, 7), t)
        #expect(click.selection.map { t.screen.text(of: $0) } == "beta")
        let forward = click.dragged(to: point(0, 13), screen: t.screen)
        #expect(forward.map { t.screen.text(of: $0) } == "beta gamma")
        let backward = click.dragged(to: point(0, 1), screen: t.screen)
        #expect(backward.map { t.screen.text(of: $0) } == "alpha beta")
    }

    @Test func `a triple click selects the line and dragging widens it by lines`() {
        let t = terminal("one\r\ntwo\r\nthree")
        let click = gesture(.lines, at: point(1, 1), t)
        #expect(click.selection.map { t.screen.text(of: $0) } == "two")
        let down = click.dragged(to: point(2, 0), screen: t.screen)
        #expect(down.map { t.screen.text(of: $0) } == "two\nthree")
        let up = click.dragged(to: point(0, 2), screen: t.screen)
        #expect(up.map { t.screen.text(of: $0) } == "one\ntwo")
    }

    @Test func `the shape is kept`() {
        let t = terminal("abcdef\r\nghijkl", 20)
        let click = SelectionGesture(at: point(0, 1), granularity: .cells, shape: .block, screen: t.screen)
        let selection = click.dragged(to: point(1, 3), screen: t.screen)
        #expect(selection?.shape == .block)
        #expect(selection.map { t.screen.text(of: $0) } == "bcd\nhij")
    }

    @Test func `selecting from empty space snaps to the nearest real text`() {
        let t = terminal("alpha beta\r\n\r\n   gamma delta", 20, 6)
        // Double-click in trailing empty space on row 0 selects the last word ("beta").
        let trailingWord = gesture(.words, at: point(0, 16), t)
        #expect(trailingWord.selection.map { t.screen.text(of: $0) } == "beta")
        // Double-click in leading spaces on row 2 selects the first word ("gamma").
        let leadingWord = gesture(.words, at: point(2, 0), t)
        #expect(leadingWord.selection.map { t.screen.text(of: $0) } == "gamma")
        // Dragging by cells from the empty bottom of the screen up to row 2 selects from the last text cell back.
        let bottomDrag = gesture(.cells, at: point(5, 10), t)
        let backward = bottomDrag.dragged(to: point(2, 9), screen: t.screen)
        #expect(backward.map { t.screen.text(of: $0) } == "delta")
        // Dragging by cells from trailing empty space on row 0 down to row 2 starts after row 0's text, not highlighting row 0's trailing blanks.
        let forwardDrag = gesture(.cells, at: point(0, 18), t)
        let forward = forwardDrag.dragged(to: point(2, 7), screen: t.screen)
        #expect(forward?.start == point(1, 0))
        #expect(forward.map { t.screen.text(of: $0) } == "\n   gamma")
    }
}
