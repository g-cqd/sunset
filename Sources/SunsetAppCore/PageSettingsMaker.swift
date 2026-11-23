package import Foundation
package import SunsetConfig
package import SunsetPane
package import SunsetWeb

/// A page's settings from the configuration (out of the app target, under tests): all profiles' `web.*`, or a profile's
/// own values over them.
package struct PageSettingsMaker: Sendable {
    /// What the pages say they are (`Version/… Safari/…`): read once by the app.
    package let applicationName: String

    package init(applicationName: String) {
        self.applicationName = applicationName
    }

    /// The settings of a page of `own` (nil: all profiles'), from `app`, the configuration of all profiles.
    package func settings(app: Configuration, own: Profile?) -> WebSettings {
        guard let own, !own.overrides.isEmpty else {
            return settings(from: app.web)
        }
        let web = ProfileOverrides.apply(own.overrides, to: app).web
        var settings = settings(from: web)
        settings.proxy = WebProxy(web.proxy)
        settings.permissionDefaults = Self.permissionDefaults(web)
        settings.downloadFolder = Self.folder(web)
        settings.askWhereToSave = web.askWhereToSave
        return settings
    }

    package func settings(from web: Configuration.Web) -> WebSettings {
        let added = web.engines.map {
            SearchEngine(name: $0.name, keyword: $0.keyword, search: $0.search, suggest: $0.suggest)
        }
        var settings = WebSettings(
            applicationName: applicationName,
            developer: web.developer,
            initialIcon: web.tabIcon != .globe,
            favicons: web.tabIcon == .favicon,
            fullFrameRate: web.fullFrameRate,
            engines: WebSettings.engines(adding: added),
            engine: web.engine,
            suggestions: web.suggestions,
            privateSuggestions: web.privateSuggestions,
            zoomScope: web.zoomScope == .site ? .site : (web.zoomScope == .session ? .session : .page),
            textOnlyZoom: web.textOnlyZoom
        )
        settings.agent = BrowserAgent(rawValue: web.agent.rawValue) ?? .safari
        settings.agentScripts = web.agentScripts
        settings.notificationAskWithoutClick = web.notificationsWithoutClick
        settings.workerNotifications = web.workerNotifications
        settings.pictureInPicture = web.pictureInPicture
        settings.autoPictureInPicture = web.autoPictureInPicture
        settings.blocking = web.blocking
        settings.httpsUpgrade = HTTPSUpgrade(rawValue: web.httpsUpgrade.rawValue) ?? .fallback
        settings.popupWindows = PopupWindows(rawValue: web.popupWindows.rawValue) ?? .sized
        settings.hardening = Hardening(rawValue: web.hardening.rawValue) ?? .off
        settings.globalPrivacyControl =
            GlobalPrivacyControl(rawValue: web.globalPrivacyControl.rawValue) ?? .privateWindows
        return settings
    }

    /// The answers to what sites may do, from `web.permissions.*`.
    package static func permissionDefaults(_ web: Configuration.Web) -> [SitePermission: PermissionAnswer] {
        var defaults: [SitePermission: PermissionAnswer] = [:]
        for (name, answer) in web.permissions {
            if let permission = SitePermission(rawValue: name), let value = PermissionAnswer(rawValue: answer.rawValue)
            {
                defaults[permission] = value
            }
        }
        return defaults
    }

    /// Where downloads go: `web.downloadFolder`, else the user's Downloads.
    package static func folder(_ web: Configuration.Web) -> URL {
        web.downloadFolder.isEmpty
            ? FileManager.default.homeDirectoryForCurrentUser.appending(path: "Downloads")
            : URL(fileURLWithPath: (web.downloadFolder as NSString).expandingTildeInPath)
    }
}
