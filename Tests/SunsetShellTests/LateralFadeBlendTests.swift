import Testing

@testable import SunsetShell
@testable import SunsetShellModel

/// Roadmap 0047 C (the owner, 2026-11-18: "the alpha masking disappearing animation could be smoother on space
/// switching"): the mask went from cut to uncut by moving its edges 400 points out, so its fade left the sidebar in the
/// first frames. It cross-fades between the two now, its edges where they are.
@Suite("The sides' fade, cross-faded")
struct LateralFadeBlendTests {
    @Test func `the cut mask and the open one are blended by weights that sum to one`() {
        #expect(LateralFade.Weights(sliding: true) == LateralFade.Weights(cut: 1, open: 0))
        #expect(LateralFade.Weights(sliding: false) == LateralFade.Weights(cut: 0, open: 1))
    }
}
