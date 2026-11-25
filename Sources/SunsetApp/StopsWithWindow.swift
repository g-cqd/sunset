import AppKit
import SunsetShell
import SwiftUI

/// Tells a window's tabs that the window closed: while another window shows their Space nothing stops; else they stop (and stay,
/// in the app's Space). Not on `onDisappear`: SwiftUI rebuilds the window's content on some settings changes
/// (window.decorations), the old content disappears while the window stays, and that stopped every program in it.
struct StopsWithWindow: ViewModifier {
    let window: NSWindow?
    let tabs: TabsModel

    func body(content: Content) -> some View {
        content.onReceive(NotificationCenter.default.publisher(for: NSWindow.willCloseNotification)) { note in
            guard let window, (note.object as? NSWindow) === window else { return }
            TabRegistry.shared.unregister(window)
            // The last window of the Space: snapshot its terminals, remember what it showed, and stop its tabs.
            TerminalHistoryRestore.saveTerminals(in: tabs)
            SessionStore.shared.closing(tabs)
            tabs.windowClosed()
            AppSpaces.cleanStopped()
            SessionStore.shared.scheduleSave()
        }
    }
}
