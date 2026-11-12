import SunsetMetrics
import SunsetPane
import SunsetShell
import SwiftUI

extension PaneArea {
    /// The focused pane's card, as the pane area draws it.
    func focusedCard(_ item: Workspace.Item, _ frames: [PaneID: CGRect], bounds: CGRect, card: Bool, radius: Double)
        -> PaneCardShape?
    {
        frames[item.focused]
            .map { frame in
                PaneCardShape(
                    frame: frame,
                    radii: TerminalCard.radii(
                        isCard: card,
                        outer: radius,
                        windowCorners: CornerSet.atCorners(of: frame, in: bounds).intersection(windowCorners),
                        layout: layout
                    )
                )
            }
    }
}
