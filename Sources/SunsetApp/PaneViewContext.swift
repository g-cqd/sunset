/// What the pane area tells the view of a pane's content.
struct PaneViewContext {
    /// The pane has the keyboard.
    var focused: Bool
    /// What is behind the window shows through the content's background.
    var translucent: Bool
    var optionAsMeta: Bool
}
