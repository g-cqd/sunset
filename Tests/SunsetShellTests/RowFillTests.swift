import Testing

@testable import SunsetShell
@testable import SunsetShellModel

/// How a tab's row is filled, decided once for the sidebar's row, the top bar's tab and a split's part (each had its
/// own copy).
@Suite("A tab's fill")
struct RowFillTests {
    @Test func `selected, hovered, in a window at the back, open, or nothing`() {
        #expect(
            RowFill.opacity(selected: true, hovering: true, inactive: false, open: false) == Design.Fill.selectedHover
        )
        #expect(
            RowFill.opacity(selected: true, hovering: false, inactive: true, open: false)
                == Design.Fill.selectedInactive
        )
        #expect(
            RowFill.opacity(selected: true, hovering: true, inactive: true, open: false)
                == Design.Fill.selectedInactiveHover
        )
        #expect(RowFill.opacity(selected: false, hovering: true, inactive: false, open: true) == Design.Fill.openHover)
        #expect(RowFill.opacity(selected: false, hovering: true, inactive: false, open: false) == Design.Fill.hover)
        #expect(RowFill.opacity(selected: false, hovering: false, inactive: false, open: true) == Design.Fill.open)
        #expect(RowFill.opacity(selected: false, hovering: false, inactive: false, open: false) == 0)
    }

    @Test func `an armed close: a red fill, deeper under the pointer`() {
        #expect(
            RowFill.armed(hovering: false) == Design.Fill.armed
                && RowFill.armed(hovering: true) == Design.Fill.armedHover
        )
        #expect(RowFill.closeButton(armed: true, over: true) == Design.Fill.armedButtonHover)
        #expect(RowFill.closeButton(armed: false, over: true) == Design.Fill.selected)
        #expect(RowFill.closeButton(armed: false, over: false) == 0)
    }
}

extension RowFillTests {
    @Test func `a marked row: the accent, stronger while shown, deeper under the pointer; else none`() {
        #expect(RowFill.marked(.marked, hovering: false) == Design.Fill.marked)
        #expect(RowFill.marked(.marked, hovering: true) == Design.Fill.markedHover)
        #expect(RowFill.marked(.markedShown, hovering: false) == Design.Fill.markedShown)
        #expect(RowFill.marked(.markedShown, hovering: true) == Design.Fill.markedShownHover)
        #expect(RowFill.marked(.shown, hovering: true) == nil && RowFill.marked(.none, hovering: false) == nil)
    }
}
