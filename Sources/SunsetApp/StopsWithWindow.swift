import AppKit
import SunsetShell
import SwiftUI

/// Stops a window's programs when the window closes. Not on `onDisappear`: SwiftUI rebuilds the window's content on some settings
/// changes (window.decorations), the old content disappears while the window stays, and that stopped every program in it (owner,
/// 2026-11-13, t226).
struct StopsWithWindow: ViewModifier {
    let window: NSWindow?
    let tabs: TabsModel

    func body(content: Content) -> some View {
        content.onReceive(NotificationCenter.default.publisher(for: NSWindow.willCloseNotification)) { note in
            guard let window, (note.object as? NSWindow) === window else { return }
            TabRegistry.shared.unregister(window)
            tabs.stopAll()
        }
    }
}
