import SunsetPane
import SunsetRuntime

/// What shows while something is dragged (`DragTargets`).
extension TabsModel {
    /// A drag began, or ended: what would take it is worked out once, and the drag is watched until the mouse button is
    /// let go (SwiftUI says nothing of a drag dropped where nothing takes it).
    package func draggedChanged() {
        dragWatch?.cancel()
        dragWatch = nil
        guard dragged != nil else {
            dragTargets = nil
            // Dropped, here or in another window: the gaps stop taking drops.
            if Self.dragOrigin === self { Self.dragOrigin = nil }
            return
        }
        dragTargets = DragTargets(
            pinned: canPinDragged,
            favorites: canDropOnFavoritesLine,
            panes: workspace.allPanes.contains { canDrop(onto: $0) }
        )
        dragWatch = runtime.task(role: .observation) { [weak self, runtime] in
            while !Task.isCancelled {
                await runtime.sleep(for: .milliseconds(100))
                guard let self, !Task.isCancelled else { return }
                if !mouseIsDown() {
                    // Let go outside every window: what is dragged opens in a new window, whatever it is (by the window
                    // it started in only: another that took the drag up only forgets it).
                    let outside = pointerOutsideWindows() && Self.dragOrigin === self
                    // Dropped where nothing took it; a drop that did take it has cleared it already. A moment more, so
                    // that a drop being done now is not cut short.
                    await runtime.sleep(for: .milliseconds(100))
                    guard !Task.isCancelled else { return }
                    if outside, dragged != nil { openDraggedInNewWindow() } else { endDrag() }
                    return
                }
            }
        }
    }

    /// The drag is over, whatever became of it.
    package func endDrag() {
        dragged = nil
        if Self.dragOrigin === self { Self.dragOrigin = nil }
    }
}
