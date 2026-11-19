import CoreGraphics
import Testing

@testable import SunsetShell
@testable import SunsetShellModel

/// The Pinned grid's tiles (roadmap 0021, P-b; the owner, 2026-11-17): four columns that share the width, "not necessarily
/// a square, but with a max and min width"; fewer columns as the sidebar narrows, down to one; twelve entries at most
/// ("up to 3x4 items or 4x3").
@Suite("The Pinned grid's geometry")
struct PinnedLayoutTests {
    @Test func `four columns share the width; a tile is no narrower than its least and no wider than its most`() {
        let layout = PinnedLayout(width: 224, count: 6)
        #expect(layout.columns == 4 && layout.rows == 2)
        #expect(layout.tile.width == (224 - 3 * PinnedLayout.gap) / 4 && layout.tile.height == PinnedLayout.height)
        #expect(layout.height == 2 * PinnedLayout.height + PinnedLayout.gap)
        let wide = PinnedLayout(width: 900, count: 4)
        #expect(wide.columns == 4 && wide.tile.width == PinnedLayout.widths.upperBound)
        #expect(PinnedLayout(width: 224, count: 0).height == 0 && PinnedLayout(width: 224, count: 0).rows == 0)
    }

    @Test
    func `as the sidebar narrows there are three columns, then two, then one, never a tile under its least width`() {
        let least = PinnedLayout.widths.lowerBound
        let gap = PinnedLayout.gap
        #expect(PinnedLayout(width: 4 * least + 3 * gap, count: 12).columns == 4)
        #expect(PinnedLayout(width: 4 * least + 3 * gap - 1, count: 12).columns == 3)
        #expect(PinnedLayout(width: 3 * least + 2 * gap - 1, count: 12).columns == 2)
        #expect(PinnedLayout(width: 2 * least + gap - 1, count: 12).columns == 1)
        #expect(PinnedLayout(width: 10, count: 12).columns == 1 && PinnedLayout(width: 10, count: 12).rows == 12)
        #expect(PinnedLayout(width: 3 * least + 2 * gap, count: 12).rows == 4, "three by four")
    }

    @Test func `a tile's place, and the slot kept for what is being dragged in`() {
        let layout = PinnedLayout(width: 224, count: 5)
        #expect(layout.frame(of: 0).origin == .zero)
        #expect(layout.frame(of: 4).origin == CGPoint(x: 0, y: PinnedLayout.height + PinnedLayout.gap))
        #expect(layout.frame(of: 1).minX == layout.tile.width + PinnedLayout.gap)
        // One more slot is one more tile, and a row more when the row is full.
        #expect(PinnedLayout(width: 224, count: 4 + 1).rows == 2 && PinnedLayout(width: 224, count: 3 + 1).rows == 1)
    }
}
