import SunsetConfig
import Testing

@testable import SunsetAppCore

/// Where the built-in bar is: over the page (hidden until the edge, or shown on the fade), or in a toolbar of its own,
/// the page below it.
@Suite("The built-in bar's place")
struct BarPlacementTests {
    @Test func `hides: over the page; shown on the fade: over the page; shown on a toolbar: a band of its own`() {
        var bar = Configuration.Tabs.Bar()
        bar.autoHide = true
        bar.backing = .toolbar
        #expect(BarPlacement(bar) == .over(hides: true), "a bar that hides is never a band")
        bar.autoHide = false
        bar.backing = .fade
        #expect(BarPlacement(bar) == .over(hides: false))
        bar.backing = .toolbar
        #expect(BarPlacement(bar) == .toolbar)
    }
}
