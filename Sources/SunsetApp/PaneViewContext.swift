/// What the pane area tells the view of a pane's content.
struct PaneViewContext {
    /// The pane has the keyboard.
    var focused: Bool
    /// What is behind the window shows through the content's background.
    var translucent: Bool
    var optionAsMeta: Bool
    /// The height at the top of the pane that the window's own controls (its buttons, the strip it is dragged by) lie over, when the pane touches the
    /// top of a window with no title bar; 0 elsewhere. A terminal draws under it and starts its text below; other content starts below it.
    var topInset = 0.0
}
