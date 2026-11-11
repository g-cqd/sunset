/// What the pane area tells the view of a pane's content.
package struct PaneViewContext {
    /// The pane has the keyboard.
    package var focused: Bool
    /// What is behind the window shows through the content's background.
    package var translucent: Bool
    package var optionAsMeta: Bool
    /// The height at the top of the pane that the window's own controls (its buttons, the strip it is dragged by) lie over, when the pane touches the
    /// top of a window with no title bar; 0 elsewhere. A terminal draws under it and starts its text below; other content starts below it.
    package var topInset = 0.0

    package init(focused: Bool, translucent: Bool, optionAsMeta: Bool, topInset: Double = 0) {
        self.focused = focused
        self.translucent = translucent
        self.optionAsMeta = optionAsMeta
        self.topInset = topInset
    }
}
