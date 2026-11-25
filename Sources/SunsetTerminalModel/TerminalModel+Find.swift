import SunsetCore

/// Wires `TerminalFind` to the terminal's screen snapshot, viewport, selection, and keyboard focus (T-3 / roadmap 0026).
extension TerminalModel {
    func configureFind() {
        find.currentScreen = { [weak self] in self?.lastScreen }
        find.currentViewportFirstLine = { [weak self] in self?.viewport.firstLine ?? 0 }
        find.currentViewportRows = { [weak self] in self?.lastScreen?.rows ?? 24 }
        find.onChanged = { [weak self] in self?.requestFrame() }
        find.onJumpToLine = { [weak self] line in self?.revealLineInViewport(line) }
        find.onClose = { [weak self] in self?.onFocusTerminalView() }
    }

    /// Scrolls `viewport` so `line` sits near the upper third of the visible screen (leaving context above and below).
    package func revealLineInViewport(_ line: Int) {
        let rows = lastScreen?.rows ?? 24
        let topTarget = max(0, line - rows / 3)
        viewport.show(line: topTarget)
        requestFrame()
    }

    /// Cmd-E: copies the current terminal selection into the find bar and searches immediately.
    package func useSelectionForFind() {
        find.useSelection(selectedText)
    }
}
