import SwiftUI

/// The Pinned grid's tiles laid out by `PinnedLayout`: the columns that fit the width given, the block centred.
struct PinnedTiles: Layout {
    /// Between two tiles: the rows' spacing (roadmap 0038 D).
    var gap = PinnedLayout.gap

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        return CGSize(width: width, height: PinnedLayout(width: width, count: subviews.count, gap: gap).height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let layout = PinnedLayout(width: bounds.width, count: subviews.count, gap: gap)
        let used = CGFloat(layout.columns) * layout.tile.width + CGFloat(layout.columns - 1) * layout.gap
        let inset = max((bounds.width - used) / 2, 0)
        for (index, subview) in subviews.enumerated() {
            let frame = layout.frame(of: index)
            subview.place(
                at: CGPoint(x: bounds.minX + inset + frame.minX, y: bounds.minY + frame.minY),
                proposal: ProposedViewSize(frame.size)
            )
        }
    }
}
