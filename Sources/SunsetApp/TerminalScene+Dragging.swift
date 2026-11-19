import SwiftUI

/// Where the window is dragged from when it draws its own top: a strip, or any surface left free.
extension TerminalScene {
    /// A transparent strip of a fixed height that drags the window (`WindowDragGesture`).
    @ViewBuilder func dragHandle(height: Double) -> some View {
        if noDecorations, height > 0 {
            windowDragSurface.frame(height: height)
        }
    }

    /// A transparent surface that drags the window from any non-interactive area above it.
    var windowDragSurface: some View {
        Color.clear.contentShape(.rect).gesture(WindowDragGesture())
    }
}
