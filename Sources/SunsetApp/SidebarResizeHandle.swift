import SunsetConfig
import SwiftUI

/// A strip next to the sidebar's trailing edge (placed by `SidebarHandle`, in the middle of the gap between the tabs and the terminal) that resizes it by dragging (`sidebar.width`, 120 to 480 pt): the window follows while it moves and the file is
/// written a moment after the last change.
struct SidebarResizeHandle: View {
    let width: Double
    /// The width of the hit box.
    let hitWidth: Double
    @State private var startWidth: Double?

    var body: some View {
        Color.clear
            .frame(width: hitWidth)
            .contentShape(.rect)
            .pointerStyle(.columnResize)
            .gesture(
                DragGesture(minimumDistance: 1, coordinateSpace: .global)
                    .onChanged { drag in
                        let start = startWidth ?? width
                        startWidth = start
                        let new = min(max(start + drag.translation.width, 120), 480)
                        AppConfiguration.shared.update { $0.sidebar.width = new }
                    }
                    .onEnded { _ in startWidth = nil }
            )
    }
}
