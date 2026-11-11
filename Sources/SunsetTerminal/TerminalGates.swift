/// Whether a terminal is shown and has the keyboard is decided twice: by its window (the key window, on screen) and by the tabs (it is the focused pane of the
/// selected tab). It is shown and focused only when both say so.
package struct TerminalGates {
    package var windowFocused = true
    package var windowVisible = true
    package var paneFocused = true
    package var paneVisible = true

    package var hasFocus: Bool { windowFocused && paneFocused }
    package var isVisible: Bool { windowVisible && paneVisible }
}
