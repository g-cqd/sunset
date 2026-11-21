package import AppKit
import SunsetShellModel

/// A window of Sunset's, minimized for the sun and brought back (no permission needed: they are Sunset's own).
extension NSWindow: ClearableOnScreen {
    package var isShown: Bool {
        isVisible && !isMiniaturized
    }

    package func clear() {
        miniaturize(nil)
    }

    package func bringBack() {
        deminiaturize(nil)
    }
}
