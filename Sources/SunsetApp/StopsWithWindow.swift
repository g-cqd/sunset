import AppKit
import SunsetShell
import SwiftUI

/// Tells a window's tabs that the window closed: while another window shows their Space nothing stops; else they stop
/// (and stay, in the app's Space). Not on `onDisappear`: SwiftUI rebuilds the window's content on some settings
/// changes (window.decorations), the old content disappears while the window stays, and that stopped every program in it (owner,
/// 2026-11-13, t226).
struct StopsWithWindow: ViewModifier {
    let window: NSWindow?
    let tabs: TabsModel

    func body(content: Content) -> some View {
        content.onReceive(NotificationCenter.default.publisher(for: NSWindow.willCloseNotification)) { note in
            guard let window, (note.object as? NSWindow) === window else { return }
            TabRegistry.shared.unregister(window)
            // The last window of the Space: what it showed is remembered, and its tabs stop and stay (ADR-0045).
            SessionStore.shared.closing(tabs)
            tabs.windowClosed()
            AppSpaces.cleanStopped()
            SessionStore.shared.scheduleSave()
        }
    }
}
