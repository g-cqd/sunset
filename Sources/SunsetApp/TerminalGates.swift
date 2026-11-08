/// Whether a terminal is shown and has the keyboard is decided twice: by its window (the key window, on screen) and by the tabs (it is the focused pane of the
/// selected tab). It is shown and focused only when both say so.
struct TerminalGates {
    var windowFocused = true
    var windowVisible = true
    var paneFocused = true
    var paneVisible = true

    var hasFocus: Bool { windowFocused && paneFocused }
    var isVisible: Bool { windowVisible && paneVisible }
}
