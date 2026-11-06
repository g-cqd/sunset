public import SunsetCore

/// The seam between the screen and whatever draws it (ADR-0024): the CPU renderer is one backend, a GPU one the other, and the host picks between them
/// at run time. A backend reads the screen (never changes it), keeps its own caches, and can be dropped and rebuilt from the screen at any time.
public protocol CellRenderer: AnyObject {
    /// Draws what changed since the last frame into `surface`. `cursorVisible` and `textBlinkVisible` are the host's blink phases; `view` is what the frame shows
    /// besides the live screen (scrolled back, selection, hovered link).
    func render(
        _ screen: Screen,
        into surface: inout Surface,
        cursorVisible: Bool,
        textBlinkVisible: Bool,
        view: FrameView
    )
    /// Forget what was drawn: the next frame draws everything (a new surface, a lost device).
    func invalidate()
}

extension CellRenderer {
    /// A frame of the live screen.
    public func render(_ screen: Screen, into surface: inout Surface, cursorVisible: Bool, textBlinkVisible: Bool) {
        render(
            screen,
            into: &surface,
            cursorVisible: cursorVisible,
            textBlinkVisible: textBlinkVisible,
            view: FrameView()
        )
    }
}
