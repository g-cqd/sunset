import SunsetMetrics
import SunsetPane
import SwiftUI

extension TabSidebar {
    /// Pins the sidebar beside the terminal (`sidebar.autoHide` off) or lets it hide and float: the sidebar symbol, filled while the sidebar is open
    /// (pinned) and outlined while it only appears on hover. Its container is a rounded square the size of the hit box, highlighted under the pointer like a
    /// tab, with its trailing edge on the tabs' trailing edge and its middle on the traffic lights'.
    /// Shows what dropping on this row will do: an insertion line at the top or bottom edge for reordering, or a left/right half highlight for splitting.
    @ViewBuilder func rowDropOverlay(_ action: TabDropAction) -> some View {
        let shape = RoundedRectangle(cornerRadius: layout.tabRadius, style: .continuous)
        switch action {
            // Before or after: the rows make room (`RowMakingRoom`); no line.
            case .moveBefore, .moveAfter:
                EmptyView()
            case .split(let edge):
                GeometryReader { proxy in
                    let half = proxy.size.width / 2
                    DropVeil(shape: shape)
                        .frame(width: half, height: proxy.size.height)
                        .offset(x: edge == .right ? half : 0)
                }
                .allowsHitTesting(false)
        }
    }

    /// How far the row moves to make room where the dragged tab would go (`RowMakingRoom`).
    func roomOffset(_ id: Workspace.ItemID) -> CGFloat {
        RowMakingRoom.offset(
            of: id,
            rows: tabs.workspace.items.map(\.id),
            gap: gapRoom,
            drop: rowDrop,
            room: layout.rowMakingRoom
        )
    }
}
