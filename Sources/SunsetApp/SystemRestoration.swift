import AppKit

/// The system's own record of the windows that were open (AppKit's saved application state): Sunset neither reads it nor
/// writes it, because it restores its own session from its sealed store (ADR-0039).
///
/// Read, it leaves Sunset with no window: a Sunset that was killed after its last window closed leaves a record of no
/// windows, kept per signing identity and so shared by every copy of Sunset, and AppKit, restoring it at the next start,
/// opens nothing (seen 2026-11-16: the installed build started with no window). Written, it keeps every window's title in
/// plain outside the sealed store (a folder, a file's name, a page's title; white paper §9).
@MainActor
enum SystemRestoration {
    /// The saved state is not looked at when Sunset starts: what `-ApplePersistenceIgnoreState YES` on the command line
    /// says, said here so that it holds however Sunset is started. Called before the application object exists.
    static func ignoreSavedState() {
        var arguments = UserDefaults.standard.volatileDomain(forName: UserDefaults.argumentDomain)
        arguments["ApplePersistenceIgnoreState"] = true
        UserDefaults.standard.setVolatileDomain(arguments, forName: UserDefaults.argumentDomain)
    }

    /// `window` is left out of the saved state: its title, its frame and its picture are not recorded.
    static func exclude(_ window: NSWindow) {
        if window.isRestorable { window.isRestorable = false }
    }

    /// Every window is left out as it comes on screen or takes the keyboard: Sunset's own, and the panels AppKit makes
    /// (Fonts, Colors, an Open panel).
    static func excludeEveryWindow() {
        guard observers.isEmpty else { return }
        for name in [NSWindow.didChangeOcclusionStateNotification, NSWindow.didBecomeKeyNotification] {
            observers.append(
                NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main) { _ in
                    MainActor.assumeIsolated { NSApp.windows.forEach(exclude) }
                }
            )
        }
        NSApp.windows.forEach(exclude)
    }

    private static var observers: [any NSObjectProtocol] = []
}
