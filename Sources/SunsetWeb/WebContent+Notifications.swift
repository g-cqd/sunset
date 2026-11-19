import Foundation
import WebKit

/// A page's notifications (roadmap 0035 D): what its `Notification` asks (`WebNotifications`) is answered here by the site's
/// standing answer; what may be shown is handed to the app (`onNotify`), which posts it to the system.
extension WebContent {
    /// Answers the page's `Notification`: `permission` (the API's word for the site's answer), `request` (asks the person when the
    /// site was not answered, from a gesture, one question at a time), `show` (true when it was handed on). Only the page itself, not a frame in it, and only by the
    /// site WebKit says it is; at most one a second.
    func notificationAsked(
        _ kind: String,
        _ fields: [String: Any],
        host: String?,
        mainFrame: Bool,
        at now: Double
    ) async -> Any? {
        guard mainFrame, let host, !host.isEmpty else { return kind == "show" ? false : "denied" }
        switch kind {
            case "permission":
                return notificationWord(host)
            case "request":
                // Asked only from what the person did, and one question at a time: else the site's answer as it stands.
                guard fields["activated"] as? Bool == true || settings.notificationAskWithoutClick, !notificationAsking,
                    permissions.answer(.notifications, for: host) == .ask, !notificationHosts.contains(host)
                else { return notificationWord(host) }
                notificationAsking = true
                defer { notificationAsking = false }
                // Allow Once: for this page's life.
                if await ask([.notifications], host: host) { notificationHosts.insert(host) }
                return notificationWord(host)
            case "show":
                guard notificationWord(host) == "granted" else { return false }
                // Through its service worker's registration: only when that is allowed (roadmap 0046 S2).
                if fields["worker"] as? Bool == true, !settings.workerNotifications { return false }
                if let last = lastNotification, now >= last, now - last < 1 { return false }
                lastNotification = now
                let id = (fields["id"] as? Int) ?? (fields["id"] as? Double).map(Int.init) ?? 0
                onNotify(
                    WebNotification(
                        id: id,
                        title: fields["title"] as? String ?? "",
                        body: fields["body"] as? String ?? "",
                        host: host,
                        tag: fields["tag"] as? String ?? "",
                        icon: fields["icon"] as? String,
                        silent: fields["silent"] as? Bool ?? false
                    )
                )
                return true
            case "clicks":
                return await notificationClicks.next()
            case "close":
                // The page takes one of its own away (roadmap 0036 E).
                if let id = (fields["id"] as? Int) ?? (fields["id"] as? Double).map(Int.init) {
                    onNotificationClose(id)
                }
                return true
            default:
                return nil
        }
    }

    /// The API's word for what the site may do: granted, denied, default (not answered).
    private func notificationWord(_ host: String) -> String {
        if notificationHosts.contains(host) { return "granted" }
        switch permissions.answer(.notifications, for: host) {
            case .allow: return "granted"
            case .deny: return "denied"
            case .ask: return "default"
        }
    }

    /// The person clicked the notification `id` this page showed: the page hears it as its `click` event.
    package func notificationClicked(_ id: Int) {
        notificationClicks.clicked(id)
    }
}
