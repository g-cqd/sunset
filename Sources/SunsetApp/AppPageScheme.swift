import AppKit
import SunsetWeb

/// Pages that follow the system's scheme (`web.pageScheme`) change with it, whatever Sunset's own scheme is.
@MainActor enum AppPageScheme {
    private static var watching = false

    /// Starts watching the system's light and dark, once.
    static func watchSystem() {
        guard !watching else { return }
        watching = true
        DistributedNotificationCenter.default()
            .addObserver(
                forName: Notification.Name("AppleInterfaceThemeChangedNotification"),
                object: nil,
                queue: .main
            ) { _ in
                MainActor.assumeIsolated {
                    for page in TabRegistry.shared.allWindows().flatMap(\.tabs.allPages) { page.applyPageScheme() }
                }
            }
    }
}
