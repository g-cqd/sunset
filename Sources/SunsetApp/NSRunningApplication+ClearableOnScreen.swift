package import AppKit
import SunsetShellModel

/// Another app, hidden for the sun and shown again: hiding needs no permission, where minimizing another app's windows
/// would need Accessibility's.
extension NSRunningApplication: ClearableOnScreen {
    package var isShown: Bool {
        !isHidden
    }

    package func clear() {
        hide()
    }

    package func bringBack() {
        unhide()
    }
}
