public import SunsetCore

/// What a frame shows besides the live screen: how far the window is scrolled back into the history, the selection and the hovered link.
public struct FrameView: Sendable, Equatable {
    /// Lines of history the window is scrolled back (0: the live screen, the only one with a cursor).
    public var scrolledBack = 0
    /// Drawn with its cells' colours swapped.
    public var selection: Selection?
    /// A link id from `Screen.linkID` (0 for none), drawn underlined.
    public var hoveredLink: UInt16 = 0
    /// How opaque the default background is (255: opaque, the normal case; less lets what is behind the window show through, with a window that has a material,
    /// glass or nothing behind it). Cells with a colour of their own, the cursor, the selection and the text stay opaque.
    public var backgroundAlpha: UInt8 = 255
    /// Pixels the view has beyond the last whole cell, to the right and below: the surface covers them, painted with the background, so that the
    /// background reaches the edges of the view whatever its size.
    public var extraWidth = 0
    public var extraHeight = 0

    public init(
        scrolledBack: Int = 0,
        selection: Selection? = nil,
        hoveredLink: UInt16 = 0,
        backgroundAlpha: UInt8 = 255,
        extraPixels: (width: Int, height: Int) = (0, 0)
    ) {
        extraWidth = max(extraPixels.width, 0)
        extraHeight = max(extraPixels.height, 0)
        self.backgroundAlpha = backgroundAlpha
        self.scrolledBack = scrolledBack
        self.selection = selection
        self.hoveredLink = hoveredLink
    }
}
