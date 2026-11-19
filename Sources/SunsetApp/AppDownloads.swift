import AppKit
import SunsetAppCore
import SunsetConfig
import SunsetRuntime
import SunsetStorage
import SunsetWeb
import UserNotifications

/// The app's side of downloads (web step f) and of site permissions (step g): the settings from `web.*`, the approval of risky kinds and the save panel, and what is done when one
/// finishes: the Dock bounces while Sunset is in the background, a notification (`web.notifyDownloads`), safe kinds opened (`web.openSafeDownloads`).
@MainActor enum AppDownloads {
    /// Where its tasks run, the clock it waits on, the time it reads (ADR-0087); `.live` unless a test sets another.
    static var runtime = Runtime.live

    static func start() {
        let center = DownloadCenter.shared
        apply(AppConfiguration.shared.configuration.web)
        let storage = AppStorage.shared
        // The browser each site is shown (W-a): kept sealed, as what each site may do is.
        SiteAgents.shared.table = storage.table("agents")
        // The sites whose data is kept (ADR-0081).
        AppKeeping.start()
        // The Space each site opens in (W-d).
        SiteSpaces.shared.table = storage.table("site-spaces")
        // The sites' icons, for tabs not loaded (roadmap 0035 H).
        FaviconStore.shared.table = storage.table("favicons")
        let permissions = storage.table("permissions")
        SitePermissions.shared.table = permissions
        if let permissions, SitePermissions.shared.importLegacy(at: storage.places.legacyPermissions) != nil {
            storage.retire(
                storage.places.legacyPermissions,
                when: permissions.count() == SitePermissions.shared.answers.count
            )
        }
        let downloads = storage.table("downloads")
        center.table = downloads
        if let downloads, center.importLegacy(at: storage.places.legacyDownloads) != nil {
            storage.retire(
                storage.places.legacyDownloads,
                when: downloads.count() == center.items.filter { !$0.isPrivate }.count
            )
        }
        center.approve = { name, origin in approve(name, origin: origin) }
        center.choose = { name in choose(name) }
        center.onFinished = { finished($0) }
    }

    static func apply(_ web: Configuration.Web) {
        applyPermissions(web)
        let folder = folder(web)
        let keep: DownloadSettings.Keep =
            switch web.keepDownloads {
                case .byHand: .byHand
                case .day: .day
                case .week: .week
                case .month: .month
                case .untilQuit: .untilQuit
                case .whenFinished: .whenFinished
            }
        DownloadCenter.shared.settings = DownloadSettings(
            folder: folder,
            askWhereToSave: web.askWhereToSave,
            openSafe: web.openSafeDownloads,
            notify: web.notifyDownloads,
            approveRisky: web.approveRiskyDownloads,
            keep: keep
        )
    }

    /// Where downloads go: the folder set, or ~/Downloads.
    static func folder(_ web: Configuration.Web) -> URL {
        PageSettingsMaker.folder(web)
    }

    /// The defaults of `web.permissions.*` (web step g).
    static func applyPermissions(_ web: Configuration.Web) {
        SitePermissions.shared.defaults = permissionDefaults(web)
    }

    static func permissionDefaults(_ web: Configuration.Web) -> [SitePermission: PermissionAnswer] {
        PageSettingsMaker.permissionDefaults(web)
    }

    private static func approve(_ name: String, origin: URL?) -> Bool {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "Download \u{201C}\(name)\u{201D}?"
        alert.informativeText =
            "It is an app, an installer or a script: opening it runs code on your Mac. It comes from \(origin?.host() ?? "a page"). "
            + "Download it only if you trust where it comes from."
        alert.addButton(withTitle: "Cancel")
        alert.addButton(withTitle: "Download")
        return alert.runModal() == .alertSecondButtonReturn
    }

    private static func choose(_ name: String) -> URL? {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = name
        panel.directoryURL = DownloadCenter.shared.settings.folder
        return panel.runModal() == .OK ? panel.url : nil
    }

    private static func finished(_ item: DownloadItem) {
        if !NSApp.isActive { NSApp.requestUserAttention(.informationalRequest) }
        let settings = DownloadCenter.shared.settings
        if settings.notify { notify(item) }
        if settings.openSafe, DownloadNaming.isSafe(item.name), let file = item.destination {
            NSWorkspace.shared.open(file)
        }
    }

    /// A system notification; the system asks once whether Sunset may send them. Only for an app with a bundle (a bare executable has none, and
    /// the notification centre stops the process without one).
    private static func notify(_ item: DownloadItem) {
        guard Bundle.main.bundleIdentifier != nil else { return }
        let name = item.name
        runtime.task {
            let center = UNUserNotificationCenter.current()
            guard (try? await center.requestAuthorization(options: [.alert])) == true else { return }
            let content = UNMutableNotificationContent()
            content.title = "Download finished"
            content.body = name
            try? await center.add(UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil))
        }
    }
}
