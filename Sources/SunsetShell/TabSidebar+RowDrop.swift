import SunsetPane
import SwiftUI

extension TabSidebar {
    /// Pins the sidebar beside the terminal (`sidebar.autoHide` off) or lets it hide and float: the sidebar symbol, filled while the sidebar is open
    /// (pinned) and outlined while it only appears on hover. Its container is a rounded square the size of the hit box, highlighted under the pointer like a
    /// tab, with its trailing edge on the tabs' trailing edge and its middle on the traffic lights'.
    /// Shows what dropping on this row will do: an insertion line at the top or bottom edge for reordering, or a left/right half highlight for splitting.
    @ViewBuilder func rowDropOverlay(_ action: TabDropAction) -> some View {
        let accent = accentStyle.color
        let shape = RoundedRectangle(cornerRadius: layout.tabRadius, style: .continuous)
        switch action {
            // In the gap beside the row, where a drop there would land (roadmap 0038 F), not on the row's edge.
            case .moveBefore:
                VStack {
                    Capsule().fill(accent).frame(height: Design.Space.hair).padding(.horizontal, Design.Space.xs)
                    Spacer(minLength: 0)
                }
                .padding(.vertical, -layout.gapMarkOutset)
                .allowsHitTesting(false)
            case .moveAfter:
                VStack {
                    Spacer(minLength: 0)
                    Capsule().fill(accent).frame(height: Design.Space.hair).padding(.horizontal, Design.Space.xs)
                }
                .padding(.vertical, -layout.gapMarkOutset)
                .allowsHitTesting(false)
            case .split(let edge):
                GeometryReader { proxy in
                    let half = proxy.size.width / 2
                    shape.fill(accent.opacity(Design.Fill.target))
                        .overlay { shape.strokeBorder(accent.opacity(Design.Fill.armedButton), lineWidth: 1.5) }
                        .frame(width: half, height: proxy.size.height)
                        .offset(x: edge == .right ? half : 0)
                }
                .allowsHitTesting(false)
        }
    }
}
