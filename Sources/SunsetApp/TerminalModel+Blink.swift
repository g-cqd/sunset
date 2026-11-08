import SunsetRender

/// The cursor's blink and what stops it.
extension TerminalModel {
    /// Something happened (a key, output): the cursor blinks again for a while, and the blink task is woken if it was waiting without a timer.
    func noteActivity() {
        lastActivity = .now
        blinkWake.continuation.yield()
    }

    /// The window gained or lost the key state, or was covered or uncovered.
    func windowStateChanged(focused: Bool, visible: Bool) {
        gates.windowFocused = focused
        gates.windowVisible = visible
        applyState()
    }

    /// The tabs changed which pane has the keyboard and which tab is shown.
    func paneStateChanged(focused: Bool, visible: Bool) {
        guard focused != gates.paneFocused || visible != gates.paneVisible else { return }
        gates.paneFocused = focused
        gates.paneVisible = visible
        applyState()
    }

    private func applyState() {
        let wasVisible = isVisible
        let visible = gates.isVisible
        hasFocus = gates.hasFocus
        isVisible = visible
        blinkWake.continuation.yield()
        if visible, !wasVisible { requestFrame() }
        if !visible { setDisplayLinkPaused(true) }
    }

    func blink() async {
        var wakes = blinkWake.stream.makeAsyncIterator()
        while !Task.isCancelled {
            let idle = ContinuousClock.now - lastActivity
            guard let wait = blinkSchedule.wait(afterIdle: idle, focused: hasFocus && isVisible), cursorBlinks else {
                // Solid: the program turned blinking off, the window is not the key window or is hidden, or nothing has happened for a long time. No timer:
                // wait for activity or for the focus to come back.
                if !cursorPhase {
                    cursorPhase = true
                    requestFrame()
                }
                if await wakes.next() == nil { return }
                continue
            }
            try? await Task.sleep(for: wait)
            // Looked at again after the sleep: the focus or the activity may have changed meanwhile.
            guard hasFocus, isVisible, cursorBlinks, blinkSchedule.blinks(afterIdle: ContinuousClock.now - lastActivity)
            else { continue }
            cursorPhase.toggle()
            requestFrame()
        }
    }
}
