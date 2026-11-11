import AppKit
import SunsetConfig
import SunsetCore
import SunsetHost
import UserNotifications

/// What the program asked of the host (ADR-0010), applied under the policy: a clipboard write goes to the pasteboard; a notification is shown only while the
/// app is not frontmost, at most one a second, and only when the process is a bundled app (the notification centre refuses a bare executable).
extension TerminalModel {
    func watchHostEvents(_ session: TerminalSession) async {
        var gate = NotificationGate()
        for await event in session.hostEvents where policy.admits(event) {
            switch event {
                case .clipboardWrite(let text):
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(text, forType: .string)
                case .notification(let title, let body):
                    let now = ProcessInfo.processInfo.systemUptime
                    guard gate.admits(atSecond: now, windowFocused: NSApp.isActive) else { continue }
                    await show(title: title, body: body)
            }
        }
    }

    /// Read for each event: a setting changed while the shell runs applies to what it asks next.
    private var policy: HostPolicy {
        HostPolicy(clipboardWrite: AppConfiguration.shared.configuration.terminal.clipboardWrite)
    }

    private func show(title: String, body: String) async {
        guard Bundle.main.bundleIdentifier != nil else { return }
        let center = UNUserNotificationCenter.current()
        guard (try? await center.requestAuthorization(options: [.alert])) == true else { return }
        let content = UNMutableNotificationContent()
        content.title = title.isEmpty ? "Sunset" : title
        content.body = body
        try? await center.add(UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil))
    }
}
