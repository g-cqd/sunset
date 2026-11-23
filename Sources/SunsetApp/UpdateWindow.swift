import AppKit
import SunsetUpdate
import SwiftUI

/// The update dialog (n135): what is new between the running build and the offered one, every release's notes, newest
/// first; Later, or Update (Restart to Update once it is ready).
@MainActor
enum UpdateWindow {
    private static var window: NSWindow?

    static func show(_ offer: UpdateOffer) {
        window?.close()
        let shown = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 560, height: 520),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        shown.title = "Sunset Update"
        shown.isReleasedWhenClosed = false
        shown.contentViewController = NSHostingController(rootView: UpdateNotes(offer: offer) { shown.close() })
        shown.center()
        shown.makeKeyAndOrderFront(nil)
        window = shown
    }
}
