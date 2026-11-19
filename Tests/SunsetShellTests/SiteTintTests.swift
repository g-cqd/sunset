import Testing

@testable import SunsetShell
@testable import SunsetShellModel

/// The owner's note n56: the variants of a tab tinted by its site's colour (its declared theme colour, else its icon's).
@Suite("A tab tinted by its site")
struct SiteTintTests {
    private let blue: [UInt8] = [10, 120, 230]

    @Test func `off: no tint; selected: the selected tab only; every: each tab, the selected one more`() {
        #expect(RowFill.siteTint(.off, selected: true, hovering: false, color: blue) == nil)
        #expect(RowFill.siteTint(.selected, selected: false, hovering: true, color: blue) == nil)
        #expect(
            RowFill.siteTint(.selected, selected: true, hovering: false, color: blue)?.opacity == RowFill.siteSelected
        )
        let resting = RowFill.siteTint(.every, selected: false, hovering: false, color: blue)
        #expect(resting?.opacity == RowFill.siteResting && resting?.rgb == blue)
        #expect(RowFill.siteTint(.every, selected: true, hovering: false, color: blue)?.opacity == RowFill.siteSelected)
        #expect(RowFill.siteTint(.every, selected: false, hovering: true, color: blue)?.opacity == RowFill.siteHover)
        #expect(
            RowFill.siteTint(.every, selected: true, hovering: false, color: nil) == nil,
            "a tab with no colour: grey"
        )
        #expect(RowFill.siteResting < RowFill.siteHover && RowFill.siteHover < RowFill.siteSelected)
    }
}
