import AppKit
import SwiftUI

/// A window whose content is Sunset's sky to every edge (the welcome, the update): no title shown, the title bar
/// transparent over the content, moved by its background, kept when closed; only the buttons asked for are shown.
@MainActor
enum SkyWindow {
    static func make(title: String, size: CGSize, showsClose: Bool, content: (NSWindow) -> some View) -> NSWindow {
        let made = NSWindow(
            contentRect: CGRect(origin: .zero, size: size),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        made.title = title
        made.titlebarAppearsTransparent = true
        made.titleVisibility = .hidden
        made.isReleasedWhenClosed = false
        made.isMovableByWindowBackground = true
        let hosting = NSHostingView(rootView: content(made))
        // The sky to every edge: no room kept for the title bar (seen as a dark strip at the bottom).
        hosting.safeAreaRegions = []
        made.contentView = hosting
        made.setContentSize(size)
        let hidden: [NSWindow.ButtonType] =
            showsClose ? [.miniaturizeButton, .zoomButton] : [.closeButton, .miniaturizeButton, .zoomButton]
        for button in hidden { made.standardWindowButton(button)?.isHidden = true }
        return made
    }
}
