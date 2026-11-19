import AppKit
package import Foundation
package import SunsetPane
import SunsetRuntime

/// Removing panes and tabs: what a close asks first, and what it stops.
extension TabsModel {
    // MARK: Removing

    /// Takes a pane out without stopping its program: the terminal goes to another window. The window is not told it is empty (the caller decides).
    package func detach(pane: PaneID) -> (any PaneContent)? {
        guard let model = contents[pane] else { return nil }
        workspace.close(pane: pane)
        contents[pane] = nil
        syncStates()
        onChange()
        return model
    }

    /// Whether `item` is currently armed for close confirmation (tinted red).
    package func isCloseArmed(_ item: Workspace.ItemID) -> Bool {
        closeConfirmation.isArmed(item: item, now: runtime.uptime())
    }

    func confirmed(_ target: CloseConfirmation.Target, isBusy: Bool) -> Bool {
        let allowed = closeConfirmation.shouldClose(
            target,
            isBusy: isBusy,
            enabled: confirmClose,
            now: runtime.uptime()
        )
        if !allowed, let deadline = closeConfirmation.expiration {
            expiryTask?.cancel()
            expiryTask = runtime.task { [weak self, runtime] in
                await runtime.sleep(until: deadline)
                guard !Task.isCancelled else { return }
                self?.closeConfirmation.expire(at: runtime.uptime())
            }
        }
        return allowed
    }

    /// The window closed: it no longer shows its Space. While another window does, nothing stops; the last window of a Space
    /// that keeps its tabs stops them and they stay; any other Space ends with its window.
    package func windowClosed(at date: Date = Runtime.live.now()) {
        space.leave(self, at: date)
        spaces?.windowClosed(at: date)
    }

    func stop(_ panes: [PaneID]) {
        for pane in panes {
            if hoveredPane == pane { hoveredPane = nil }
            contents[pane]?.stop()
            contents[pane] = nil
        }
    }

    /// The window goes with its last tab, unless it shows a kept entry or there are Favorites to show (it stays, with a hint: R3).
    func finishClosing() {
        onChange()
        if workspace.isEmpty, workspace.selectedEntry == nil, favorites.isEmpty { emptied() } else { syncStates() }
    }
}
