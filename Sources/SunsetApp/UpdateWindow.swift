import AppKit
import SunsetShell
import SunsetUpdate
import SwiftUI

/// The update dialog (n135): what is new between the running build and the offered one, every release's notes, newest
/// first; Later, or Update (Restart to Update once it is ready).
@MainActor
enum UpdateWindow {
    private static var window: NSWindow?

    static func show(_ offer: UpdateOffer) {
        window?.close()
        let shown = SkyWindow.make(title: "Sunset Update", size: Design.Update.size, showsClose: true) { shown in
            UpdateNotes(offer: offer) { [weak shown] in shown?.close() }
        }
        shown.center()
        shown.makeKeyAndOrderFront(nil)
        window = shown
    }

    /// Closes it, when it is shown.
    static func close() {
        window?.close()
        window = nil
    }
}
