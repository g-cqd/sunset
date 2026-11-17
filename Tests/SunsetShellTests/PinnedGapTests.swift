import CoreGraphics
import Testing

@testable import SunsetShell

/// The owner, 2026-11-17 (roadmap 0038 D): "the spacing between tabs of the pinned grid should be similar to the one between
/// tabs": the grid's gap is the rows' spacing, whatever it is set to.
@Suite("The Pinned grid's gap")
struct PinnedGapTests {
    @Test func `the gap between tiles, across and down, is the one given: the rows' spacing`() {
        let layout = PinnedLayout(width: 224, count: 8, gap: 4)
        #expect(layout.frame(of: 1).minX - layout.frame(of: 0).maxX == 4)
        #expect(layout.frame(of: 4).minY - layout.frame(of: 0).maxY == 4)
        #expect(layout.tile.width == 53, "\(layout.tile.width)")
    }
}
