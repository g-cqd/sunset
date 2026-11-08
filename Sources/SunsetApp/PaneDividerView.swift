import SunsetPane
import SwiftUI

/// The space between two cards (the window's colour; no line of its own): a strip over it, at least 8 pt wide, that drags. The drag reports the ratio the split would have with the
/// pointer in the middle of the gap (`SplitDivider.ratio(at:)`, which keeps it away from the ends).
struct PaneDividerView: View {
    let divider: SplitDivider
    let space: String
    let resize: (Double) -> Void

    /// The hit area is at least this wide, so that a gap of a point or two can still be grabbed.
    private static let grab = 8.0

    var body: some View {
        let horizontal = divider.axis == .horizontal
        let width = horizontal ? max(divider.gap.width, Self.grab) : divider.gap.width
        let height = horizontal ? divider.gap.height : max(divider.gap.height, Self.grab)
        Color.clear
            .frame(width: width, height: height)
            .contentShape(.rect)
            .pointerStyle(horizontal ? .columnResize : .rowResize)
            .gesture(
                DragGesture(minimumDistance: 1, coordinateSpace: .named(space))
                    .onChanged { drag in resize(divider.ratio(at: drag.location)) }
            )
            .offset(x: divider.gap.midX - width / 2, y: divider.gap.midY - height / 2)
    }
}
