import AppKit
import SunsetShell
import SwiftUI

/// ⌘V in the window while the clipboard holds a picture and no text: the picture goes to `pasted` (an entry's page reads
/// it for a QR code), not to the field that has the keyboard, which could not take it. Text is pasted as ever.
struct QRPasteCatcher: View {
    let pasted: @MainActor (CGImage) -> Void

    var body: some View {
        EventCatcher(events: .keyDown) { event, view in
            guard event.window === view.window,
                event.modifierFlags.intersection(.deviceIndependentFlagsMask) == .command,
                event.charactersIgnoringModifiers == "v",
                NSPasteboard.general.string(forType: .string) == nil,
                let image = QRCodeImages.image()
            else { return false }
            pasted(image)
            return true
        }
    }
}
