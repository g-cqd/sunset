import AppKit
import SunsetAppCore
import SunsetConfig
import SunsetDocuments
import SunsetPane
import SunsetRuntime
import SunsetShellModel
import SunsetStorage
import SunsetWeb
import UserNotifications

/// The app's side of downloads and of site permissions: the settings from `web.*`, the approval of risky kinds and the save panel, and what is done when one
/// finishes: the Dock bounces while Sunset is in the background, a notification (`web.notifyDownloads`), safe kinds opened (`web.openSafeDownloads`).
@MainActor enum AppDownloads {
    /// Where its tasks run, the clock it waits on, the time it reads; `.live` unless a test sets another.
    static var runtime = Runtime.live

    static func start() {
        let center = DownloadCenter.shared
        apply(AppConfiguration.shared.configuration.web)
        let storage = SunsetStore.shared
        // The browser each site is shown: kept sealed, as what each site may do is.
        SiteAgents.shared.table = storage.table("agents")
        // The sites whose data is kept.
        AppKeeping.start()
        // The Space each site opens in.
        SiteSpaces.shared.table = storage.table("site-spaces")
        // The sites' icons, for tabs not loaded.
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
        center.approve = { name, origin in await approve(name, origin: origin) }
        // What Sunset opens (drawn or as text) opens in a tab, with documents on; the rest in the Mac's app for it.
        center.open = { file in
            if AppScopes.current.documents,
                DocumentKind.opens(path: file.path) || PaneDescriptor.isViewed(path: file.path)
            {
                AppActions.shared.open(files: [file.path])
            } else {
                NSWorkspace.shared.open(file)
            }
        }
        center.choose = { name in choose(name) }
        center.onFinished = { finished($0) }
    }

    static func apply(_ web: Configuration.Web) {
        applyPermissions(web)
        DownloadCenter.shared.settings = DownloadSettingsMaker.make(web, folder: folder(web))
    }

    /// Where downloads go: the folder set, or ~/Downloads.
    static func folder(_ web: Configuration.Web) -> URL {
        PageSettingsMaker.folder(web)
    }

    /// The defaults of `web.permissions.*`.
    static func applyPermissions(_ web: Configuration.Web) {
        SitePermissions.shared.defaults = permissionDefaults(web)
    }

    static func permissionDefaults(_ web: Configuration.Web) -> [SitePermission: PermissionAnswer] {
        PageSettingsMaker.permissionDefaults(web)
    }

    /// Cancel is the default: Return does not download (in Sunset's look).
    private static func approve(_ name: String, origin: URL?) async -> Bool {
        let alert = SunsetAlert(
            title: "Download \u{201C}\(name)\u{201D}?",
            message: "It is an app, an installer or a script: opening it runs code on your Mac. It comes from "
                + "\(origin?.host() ?? "a page"). Download it only if you trust where it comes from.",
            buttons: [.cancel("Cancel"), .plain("Download")],
            defaultButton: 0
        )
        return await SunsetAlerts.ask(alert) == 1
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
            DownloadCenter.shared.open(file)
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
