import CoreGraphics
import Foundation
import Testing

@testable import SunsetPane

@Suite("The shape of a tab from what its panes drew") struct SplitAspectTests {
    let a = PaneID(), b = PaneID()

    @Test func `one pane is its own shape`() {
        let aspect = SplitLayout.pane(a).aspect(drawn: [a: CGSize(width: 1600, height: 1000)])
        #expect(aspect == 0.625)
    }

    @Test func `a pane that has a third of the width says the whole is three times as wide`() throws {
        let layout = SplitLayout.split(.horizontal, ratio: 1.0 / 3, first: .pane(a), second: .pane(b))
        let aspect = try #require(layout.aspect(drawn: [a: CGSize(width: 500, height: 1000)]))
        #expect(abs(aspect - 1000.0 / 1500) < 0.001)
    }

    @Test func `nothing drawn, no shape`() {
        #expect(SplitLayout.pane(a).aspect(drawn: [:]) == nil)
        #expect(SplitLayout.pane(a).aspect(drawn: [b: CGSize(width: 10, height: 10)]) == nil)
    }
}
