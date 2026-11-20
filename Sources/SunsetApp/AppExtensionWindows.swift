import AppKit
import SunsetRuntime
import SunsetShellModel
import SunsetWeb

/// Sunset's windows as extensions see them (roadmap 0109 B): one object for each window while it is open (WebKit tells them
/// apart by it), its Space's pages its tabs, the page it shows the active one; the hosts told as windows open, close and take
/// the keyboard.
@MainActor
enum AppExtensionWindows {
    private static var made: [ObjectIdentifier: ExtensionWindow] = [:]
    /// The window notifications watched, for as long as the app runs.
    private static var watches: [any NSObjectProtocol] = []

    static func start() {
        ExtensionHosts.shared.windows = { current() }
        ExtensionHosts.shared.focused = {
            guard let key = NSApp.keyWindow else { return nil }
            return current().first { $0.window === key }
        }
        let center = NotificationCenter.default
        for name in [NSWindow.didBecomeKeyNotification, NSWindow.willCloseNotification] {
            watches.append(
                center.addObserver(forName: name, object: nil, queue: .main) { _ in
                    MainActor.assumeIsolated { syncSoon() }
                }
            )
        }
    }

    /// A turn later: a window closing is still listed while it says so.
    private static func syncSoon() {
        Runtime.live.task { @MainActor in
            await Runtime.live.yieldTurn()
            ExtensionHosts.shared.sync()
        }
    }

    private static func current() -> [ExtensionWindow] {
        let open = TabRegistry.shared.allWindows()
        var now: [ObjectIdentifier: ExtensionWindow] = [:]
        let windows = open.map { window, tabs in
            let id = ObjectIdentifier(window)
            let found =
                made[id]
                ?? ExtensionWindow(
                    profile: PaneContentKinds.profile(of: tabs),
                    isPrivate: tabs.isPrivateWindow,
                    window: window,
                    pages: { [weak tabs] in tabs?.contents.values.compactMap { $0 as? WebContent } ?? [] },
                    shown: { [weak tabs] in tabs?.selectedContent as? WebContent }
                )
            now[id] = found
            return found
        }
        made = now
        return windows
    }
}
