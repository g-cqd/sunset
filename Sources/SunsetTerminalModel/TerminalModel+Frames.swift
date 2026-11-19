package import SunsetCore
import SunsetHost
import SunsetRenderMac

/// What follows a frame.
extension TerminalModel {
    package func presented(changed: Bool, snapshot: Screen) {
        renderInFlight = false
        cursorBlinks = snapshot.cursorBlinks
        apply(TerminalStatus(snapshot))
        if changed, let latest = renderer?.latest {
            lastSurface = latest
            presentFrame(latest)
        }
        // Quiet, or no longer shown, for a while: the renderer keeps the surface on screen and lets the others go.
        frameRest.frameDrawn { [weak self] in await self?.renderer?.rest() ?? true }
        checkForeground()
        if renderer?.hasFailed == true { fallBackToCPU() }
        // Something may have changed while this frame was being drawn.
        if frameWanted { setDisplayLinkPaused(false) }
    }
}
