import SunsetConfig
import Testing

@testable import SunsetHost

@Suite("Traffic lights on either side") struct LightsLayoutTests {
    @Test func `on the left the buttons run left to right from the inset`() {
        #expect(LightsLayout.x(index: 0, side: .left, inset: 12, windowWidth: 800, spacing: 20, buttonWidth: 14) == 12)
        #expect(LightsLayout.x(index: 2, side: .left, inset: 12, windowWidth: 800, spacing: 20, buttonWidth: 14) == 52)
    }

    @Test func `on the right they are mirrored: the close button is nearest the edge, the zoom button farthest`() {
        // The close button ends 12 pt from the right edge: 800 - 12 - 14.
        #expect(
            LightsLayout.x(index: 0, side: .right, inset: 12, windowWidth: 800, spacing: 20, buttonWidth: 14) == 774
        )
        #expect(
            LightsLayout.x(index: 1, side: .right, inset: 12, windowWidth: 800, spacing: 20, buttonWidth: 14) == 754
        )
        #expect(
            LightsLayout.x(index: 2, side: .right, inset: 12, windowWidth: 800, spacing: 20, buttonWidth: 14) == 734
        )
    }
}
