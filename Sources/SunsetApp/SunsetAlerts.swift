import AppKit
import SunsetShell
import SunsetShellBridge
import SunsetShellModel
import SunsetTerminal

/// Sunset's alerts on the window in front, in the configuration's look.
@MainActor
enum SunsetAlerts {
    /// The alert on `window` (or the window in front), answered once with the index of the button pressed.
    static func ask(_ alert: SunsetAlert, in window: NSWindow? = nil) async -> Int {
        await withCheckedContinuation { continuation in
            show(alert, in: window) { continuation.resume(returning: $0) }
        }
    }

    /// The look of alerts made outside the app's target (a terminal's paste warning), from the configuration.
    static func apply() {
        PasteWarning.style = SurfaceStyle(AppConfiguration.shared.configuration)
    }

    static func show(_ alert: SunsetAlert, in window: NSWindow? = nil, answer: @escaping @MainActor (Int) -> Void) {
        SunsetAlertSheet.show(
            alert,
            on: window ?? NSApp.keyWindow ?? NSApp.mainWindow,
            style: SurfaceStyle(AppConfiguration.shared.configuration),
            answer: answer
        )
    }
}
