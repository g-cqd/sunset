import AppKit
import Foundation
import SunsetRuntime
import SunsetShell
import SunsetWeb
import UserNotifications

/// A page's notifications as the system's: posted to the notification centre, shown even while Sunset is in front; a
/// click shows the page's tab in its window and tells the page. The system asks once whether Sunset may notify.
@MainActor
final class AppWebNotifications: NSObject, UNUserNotificationCenterDelegate {
    /// Where its tasks run, the clock it waits on, the time it reads; `.live` unless a test sets another.
    var runtime = Runtime.live

    static let shared = AppWebNotifications()

    /// The pane each posted notification came from (a page, a terminal), by its request's identifier; a page's own id.
    var posted: [String: (from: WeakContent, id: Int)] = [:]

    struct WeakContent {
        weak var content: (any PaneContent)?
        var page: WebContent? {
            content as? WebContent
        }
    }

    /// Becomes the notification centre's delegate. Only for an app with a bundle: without one the centre stops the process.
    static func start() {
        guard Bundle.main.bundleIdentifier != nil else { return }
        UNUserNotificationCenter.current().delegate = shared
    }

    /// Posts what `page` may show (`WebContent.onNotify` has checked the site's answer and cleaned the text).
    func post(_ note: WebNotification, from page: WebContent) {
        guard Bundle.main.bundleIdentifier != nil else { return }
        // With a tag, the site's later one with the same tag replaces it.
        let identifier = note.tag.isEmpty ? UUID().uuidString : "web|\(note.host)|\(note.tag)"
        remember(identifier, from: page, id: note.id)
        let space = spaceName(of: page)
        runtime.task {
            let center = UNUserNotificationCenter.current()
            guard (try? await center.requestAuthorization(options: [.alert, .sound])) == true else { return }
            let content = UNMutableNotificationContent()
            content.title = note.title.isEmpty ? note.host : note.title
            content.subtitle = [note.title.isEmpty ? nil : note.host, space].compactMap { $0 }
                .joined(separator: " \u{00B7} ")
            content.body = note.body
            // The page asked for no sound, or has not.
            content.sound = note.silent ? nil : .default
            // A later one with the same tag is a new alert: macOS shows a replaced banner again.
            content.interruptionLevel = .active
            if let file = await page.notificationIcon(for: note) {
                // The centre moves the file it takes; one it refuses is ours to remove.
                if let picture = try? UNNotificationAttachment(identifier: "icon", url: file) {
                    content.attachments = [picture]
                } else {
                    try? FileManager.default.removeItem(at: file)
                }
            }
            try? await center.add(UNNotificationRequest(identifier: identifier, content: content, trigger: nil))
        }
    }

    /// The page took a notification of its own away (`close()`).
    func close(_ id: Int, from page: WebContent) {
        let identifiers = posted.filter { $0.value.from.page === page && $0.value.id == id }.map(\.key)
        guard !identifiers.isEmpty else { return }
        for identifier in identifiers { posted[identifier] = nil }
        let center = UNUserNotificationCenter.current()
        center.removeDeliveredNotifications(withIdentifiers: identifiers)
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        // A page's, as a browser shows them; the others (a download, a terminal's) as before the delegate: not while in front.
        let identifier = notification.request.identifier
        return await MainActor.run { posted[identifier] != nil } ? [.banner, .list, .sound] : []
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let identifier = response.notification.request.identifier
        await MainActor.run { clicked(identifier) }
    }

    /// The notification was clicked: its pane's tab is shown in the window that holds it, in front (a window goes to its
    /// Space when none shows it: S-e), and a page hears it.
    private func clicked(_ identifier: String) {
        guard let found = posted[identifier], let content = found.from.content else { return }
        reveal(content)
        found.from.page?.notificationClicked(found.id)
    }
}
