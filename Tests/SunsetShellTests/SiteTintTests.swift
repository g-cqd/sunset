import SunsetPane
import Testing

@testable import SunsetShell
@testable import SunsetShellModel

/// The variants of a tab tinted by its site's colour (its icon's, else its declared theme colour).
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

    /// The owner's note n118: a tab's colour is the icon it shows: one the person gave it, in its colour (none without
    /// one, an emoji included); otherwise the site's.
    @Test func `a tab's colour follows the icon it shows`() {
        let site: [UInt8] = [200, 30, 30]
        #expect(RowFill.tabColor(custom: nil, site: site) == site)
        #expect(
            RowFill.tabColor(custom: .symbol("star", color: IconColor(red: 10, green: 120, blue: 250)), site: site) == [
                10, 120, 250
            ]
        )
        #expect(RowFill.tabColor(custom: .symbol("star"), site: site) == nil)
        #expect(RowFill.tabColor(custom: .emoji("🔥"), site: site) == nil)
        #expect(RowFill.tabColor(custom: nil, site: nil) == nil)
    }
}
