import AppKit
import Foundation
import SunsetShell
import SunsetWeb
import UserNotifications

/// A page's notifications as the system's (roadmap 0035 D): posted to the notification centre, shown even while Sunset is in
/// front; a click shows the page's tab in its window and tells the page. The system asks once whether Sunset may notify.
@MainActor
final class AppWebNotifications: NSObject, UNUserNotificationCenterDelegate {
    static let shared = AppWebNotifications()

    /// The page each posted notification came from, by its request's identifier.
    private var posted: [String: (page: WeakPage, id: Int)] = [:]

    struct WeakPage {
        weak var page: WebContent?
    }

    /// Becomes the notification centre's delegate. Only for an app with a bundle: without one the centre stops the process.
    static func start() {
        guard Bundle.main.bundleIdentifier != nil else { return }
        UNUserNotificationCenter.current().delegate = shared
    }

    /// Posts what `page` may show (`WebContent.onNotify` has checked the site's answer and cleaned the text).
    func post(_ note: WebNotification, from page: WebContent) {
        guard Bundle.main.bundleIdentifier != nil else { return }
        let identifier = UUID().uuidString
        posted[identifier] = (WeakPage(page: page), note.id)
        posted = posted.filter { $0.value.page.page != nil }
        Task {
            let center = UNUserNotificationCenter.current()
            guard (try? await center.requestAuthorization(options: [.alert, .sound])) == true else { return }
            let content = UNMutableNotificationContent()
            content.title = note.title.isEmpty ? note.host : note.title
            content.subtitle = note.title.isEmpty ? "" : note.host
            content.body = note.body
            try? await center.add(UNNotificationRequest(identifier: identifier, content: content, trigger: nil))
        }
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

    /// The notification was clicked: its page's tab is shown in the window that holds it, in front, and the page hears it.
    private func clicked(_ identifier: String) {
        guard let found = posted[identifier], let page = found.page.page else { return }
        for (window, tabs) in TabRegistry.shared.allWindows() where tabs.reveal(page) {
            NSApp.activate()
            TabRegistry.shared.select(window)
            window.makeKeyAndOrderFront(nil)
            break
        }
        page.notificationClicked(found.id)
    }
}
