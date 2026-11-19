import SunsetCore
import SunsetHost
import SunsetRender
import SunsetRenderMac

extension TerminalModel {
    /// Draws one frame now, shown or not: the display link's, and a call's this terminal is shared into (ADR-0082), which
    /// asks for frames while its tab is hidden. One at a time.
    package func drawFrame() async {
        guard !renderInFlight, session != nil, renderer != nil else { return }
        renderInFlight = true
        await drawClaimed()
    }

    /// The frame, once claimed (`renderInFlight` set).
    package func drawClaimed() async {
        guard let session, let renderer else {
            renderInFlight = false
            return
        }
        let phase = cursorPhase
        let alpha = backgroundAlpha
        let snapshot = await session.takeSnapshot()
        viewport.follow(historyCount: snapshot.scrollbackCount)
        lastScreen = snapshot
        let changed = await renderer.present(
            snapshot,
            cursorVisible: phase || !snapshot.cursorBlinks,
            textBlinkVisible: phase,
            view: FrameView(
                scrolledBack: viewport.scrolledBack,
                selection: selection,
                hoveredLink: hoveredLink,
                backgroundAlpha: alpha,
                extraPixels: extraPixels(for: snapshot)
            )
        )
        presented(changed: changed, snapshot: snapshot)
    }
}
