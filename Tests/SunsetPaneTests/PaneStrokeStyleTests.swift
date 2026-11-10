import Foundation
import SunsetPane
import Testing

@Suite("Pane stroke style") struct PaneStrokeStyleTests {
    @Test func `a non-card has no stroke`() {
        let a = PaneID()
        let b = PaneID()
        #expect(PaneStrokeStyle.of(pane: a, isCard: false, isSplit: true, focused: a, hovered: nil) == .none)
        #expect(PaneStrokeStyle.of(pane: a, isCard: false, isSplit: true, focused: b, hovered: a) == .none)
    }

    @Test func `a single-pane card uses the standard hairline even when focused or hovered`() {
        let a = PaneID()
        #expect(PaneStrokeStyle.of(pane: a, isCard: true, isSplit: false, focused: a, hovered: nil) == .hairline)
        #expect(PaneStrokeStyle.of(pane: a, isCard: true, isSplit: false, focused: a, hovered: a) == .hairline)
    }

    @Test
    func
        `in a split, the focused pane uses the accent stroke, the hovered unfocused pane the hover stroke, and others the hairline`()
    {
        let a = PaneID()
        let b = PaneID()
        let c = PaneID()
        #expect(PaneStrokeStyle.of(pane: a, isCard: true, isSplit: true, focused: a, hovered: nil) == .focused)
        #expect(PaneStrokeStyle.of(pane: a, isCard: true, isSplit: true, focused: a, hovered: a) == .focused)
        #expect(PaneStrokeStyle.of(pane: b, isCard: true, isSplit: true, focused: a, hovered: b) == .hovered)
        #expect(PaneStrokeStyle.of(pane: c, isCard: true, isSplit: true, focused: a, hovered: b) == .hairline)
    }
}
