/// How strongly a tab's row is filled (the sidebar's row, the top bar's tab and a split's part each worked it out): an
/// opacity of the primary colour, or of red for a close that waits for a second click.
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

extension RowFill {
    /// A row among several selected, in the accent: stronger while its tab is shown, deeper under the pointer; nil for a
    /// row that is not marked (its own fill then).
    package static func marked(_ emphasis: RowEmphasis, hovering: Bool) -> Double? {
        switch emphasis {
            case .marked: hovering ? Design.Fill.markedHover : Design.Fill.marked
            case .markedShown: hovering ? Design.Fill.markedShownHover : Design.Fill.markedShown
            case .shown, .none: nil
        }
    }
}

extension RowFill {
    /// Which tabs take their site's colour (`tabs.siteColor`).
    package enum SiteTintMode: Hashable, Sendable {
        case off, selected, every
    }

    /// A fill in the site's colour: its sRGB bytes, and how strongly.
    package struct SiteTint: Equatable, Sendable {
        package let rgb: [UInt8]
        package let opacity: Double
    }

    /// A tab at rest, under the pointer, and selected, in its site's colour (the selected one stands out the most).
    package static let siteResting = 0.12
    package static let siteHover = 0.2
    package static let siteSelected = 0.32

    /// The tab's fill in its site's colour; nil where it keeps the grey ones: off, no colour, or (selected only) not selected.
    package static func siteTint(_ mode: SiteTintMode, selected: Bool, hovering: Bool, color: [UInt8]?) -> SiteTint? {
        guard let color, color.count >= 3 else { return nil }
        let opacity: Double? =
            switch mode {
                case .off: nil
                case .selected: selected ? siteSelected : nil
                case .every: selected ? siteSelected : hovering ? siteHover : siteResting
            }
        return opacity.map { SiteTint(rgb: Array(color.prefix(3)), opacity: $0) }
    }
}
