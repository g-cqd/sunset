/// How strongly a tab's row is filled (roadmap 0086 E: the sidebar's row, the top bar's tab and a split's part each worked it
/// out): an opacity of the primary colour, or of red for a close that waits for a second click.
package enum RowFill {
    /// Selected (fainter in a window at the back), under the pointer, open in this window, or none.
    package static func opacity(selected: Bool, hovering: Bool, inactive: Bool, open: Bool) -> Double {
        switch (selected, hovering) {
            case (true, true): inactive ? Design.Fill.selectedInactiveHover : Design.Fill.selectedHover
            case (true, false): inactive ? Design.Fill.selectedInactive : Design.Fill.selected
            case (false, true): open ? Design.Fill.openHover : Design.Fill.hover
            case (false, false): open ? Design.Fill.open : 0
        }
    }

    /// A row whose close waits for a second click: red, deeper under the pointer.
    package static func armed(hovering: Bool) -> Double {
        hovering ? Design.Fill.armedHover : Design.Fill.armed
    }

    /// The close button's own fill: red when armed, a faint square under the pointer, else none.
    package static func closeButton(armed: Bool, over: Bool) -> Double {
        if armed {
            return over ? Design.Fill.armedButtonHover : Design.Fill.armedButton
        }
        return over ? Design.Fill.selected : 0
    }
}
