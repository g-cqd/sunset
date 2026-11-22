import SunsetConfig
import SunsetCore
package import SunsetHost
import UserNotifications

/// What the program asked of the host, applied under the policy: a clipboard write goes to the pasteboard; a notification is shown only while the
/// pane is not seen (a tab in the background of Sunset in front notifies), at most one a second, and only when the process is a bundled app (the
/// notification centre refuses a bare executable).
extension TerminalModel {
    package func watchHostEvents(_ session: TerminalSession) async {
        var gate = NotificationGate()
        for await event in session.hostEvents where policy.admits(event) {
            switch event {
                case .clipboardWrite(let text):
                    writeClipboard(text)
                case .notification(let title, let body):
                    let now = ProcessInfo.processInfo.systemUptime
                    let seen = NotificationGate.seen(
                        appActive: appIsActive(),
                        windowKey: gates.windowFocused,
                        windowVisible: gates.windowVisible,
                        paneVisible: gates.paneVisible
                    )
                    guard gate.admits(atSecond: now, windowFocused: seen) else { continue }
                    if let post { post(title, body) } else { await Self.show(title: title, body: body) }
            }
        }
    }

    /// Read for each event: a setting changed while the shell runs applies to what it asks next.
    private var policy: HostPolicy {
        hostPolicy()
    }

    /// Posts a program's notification to the notification centre: only for a bundled app (the centre stops a bare
    /// executable), once Sunset may notify.
    /// - Parameters:
    ///   - title: the program's title; "Sunset" when it gave none.
    ///   - subtitle: what names where it came from (the tab, the Space: S-e).
    ///   - body: the program's text.
    ///   - identifier: the request's identifier, for a click to find its pane.
    package static func show(
        title: String,
        subtitle: String = "",
        body: String,
        identifier: String = UUID().uuidString
    ) async {
        guard Bundle.main.bundleIdentifier != nil else { return }
        let center = UNUserNotificationCenter.current()
        guard (try? await center.requestAuthorization(options: [.alert])) == true else { return }
        let content = UNMutableNotificationContent()
        content.title = title.isEmpty ? "Sunset" : title
        content.subtitle = subtitle
        content.body = body
        try? await center.add(UNNotificationRequest(identifier: identifier, content: content, trigger: nil))
    }
}
