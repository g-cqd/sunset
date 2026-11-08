import SunsetConfig
import SunsetHost
import SwiftUI

/// A strip next to the sidebar's trailing edge (placed by `SidebarHandle`, in the middle of the gap between the tabs and the terminal) that resizes it by dragging (`sidebar.width`, 120 to 480 pt): the window follows while it moves and the file is
/// written a moment after the last change.
struct SidebarResizeHandle: View {
    let width: Double
    /// The width of the hit box.
    let hitWidth: Double
    /// The window's edge the sidebar is on: dragging toward the terminal widens it.
    let side: Configuration.Side
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
                        let new = SidebarHandle.width(start: start, drag: drag.translation.width, side: side)
                        AppConfiguration.shared.update { $0.sidebar.width = new }
                    }
                    .onEnded { _ in startWidth = nil }
            )
    }
}
