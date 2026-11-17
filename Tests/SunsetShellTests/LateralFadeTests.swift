import Testing

@testable import SunsetShell

/// The owner, 2026-11-17: the swipe between Spaces is clipped to the sidebar and fades at its sides, not drawn under the
/// panes. At rest nothing is clipped (a drop's outline reaches past the rows).
@Suite("The sides of a Space's swipe")
struct LateralFadeTests {
    @Test func `sliding, the list fades at its sides; at rest it is not clipped`() {
        let sliding = LateralFade.Shape(sliding: true)
        #expect(sliding.fade == Design.Space.l && sliding.overhang == 0)
        let resting = LateralFade.Shape(sliding: false)
        #expect(resting.fade == 0 && resting.overhang > 0)
    }
}
