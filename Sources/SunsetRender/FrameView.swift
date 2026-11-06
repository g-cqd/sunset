public import SunsetCore

/// What a frame shows besides the live screen: how far the window is scrolled back into the history, the selection and the hovered link.
public struct FrameView: Sendable, Equatable {
    /// Lines of history the window is scrolled back (0: the live screen, the only one with a cursor).
    public var scrolledBack = 0
    /// Drawn with its cells' colours swapped.
    public var selection: Selection?
    /// A link id from `Screen.linkID` (0 for none), drawn underlined.
    public var hoveredLink: UInt16 = 0

    public init(scrolledBack: Int = 0, selection: Selection? = nil, hoveredLink: UInt16 = 0) {
        self.scrolledBack = scrolledBack
        self.selection = selection
        self.hoveredLink = hoveredLink
    }
}
