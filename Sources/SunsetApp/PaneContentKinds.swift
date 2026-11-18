import Foundation
import SunsetConfig
import SunsetMarkdown
import SunsetPane
import SunsetShell
import SunsetWeb

/// The kinds of content besides the terminal (which the scene makes, with its configuration): what a saved descriptor becomes.
@MainActor enum PaneContentKinds {
    /// The content `descriptor` says; a kind this build does not have is kept as a placeholder. `changed` is called when the content has something
    /// new to save.
    /// - Parameters:
    ///   - descriptor: what to make.
    ///   - privacy: a private page's store, in a private window.
    ///   - profile: the profile of the Space the content is made in (nil: the first), whose website data a page uses.
    ///   - changed: called when the content has something new to save.
    /// - Returns: the content, or a placeholder for a kind this build does not have.
    static func make(
        _ descriptor: PaneDescriptor,
        privacy: PagePrivacy? = nil,
        profile: UUID? = nil,
        changed: @escaping () -> Void
    ) -> any PaneContent {
        switch descriptor.kind {
            case WebContent.kind:
                var settings = webSettings
                settings.profile = profile
                settings.privacy = privacy ?? (descriptor.state["private"] == "1" ? PagePrivacy() : nil)
                let page = WebContent(descriptor: descriptor, settings: settings)
                page.onChange = changed
                return page
            case DocumentContent.kind:
                // One that names no document is kept as it was written.
                guard let document = DocumentContent(descriptor, documents: AppStorage.shared.openDocuments) else {
                    return UnknownContent(descriptor)
                }
                document.onChange = changed
                return document
            case SettingsContent.kind:
                let settings = SettingsContent(descriptor)
                settings.onChange = changed
                return settings
            case HelpContent.kind:
                let help = HelpContent(descriptor)
                help.onChange = changed
                return help
            default:
                return UnknownContent(descriptor)
        }
    }

    /// What pages are made with, from `web.*`.
    static var webSettings: WebSettings { webSettings(from: AppConfiguration.shared.configuration.web) }

    /// A page's settings from a configuration's (all profiles', or one profile's with its own values, roadmap 0050).
    static func webSettings(from web: Configuration.Web) -> WebSettings {
        let added = web.engines.map {
            SearchEngine(name: $0.name, keyword: $0.keyword, search: $0.search, suggest: $0.suggest)
        }
        var settings = WebSettings(
            applicationName: safariName,
            developer: web.developer,
            initialIcon: web.tabIcon != .globe,
            favicons: web.tabIcon == .favicon,
            fullFrameRate: web.fullFrameRate,
            engines: WebSettings.engines(adding: added),
            engine: web.engine,
            suggestions: web.suggestions,
            httpFallback: web.httpFallback,
            privateSuggestions: web.privateSuggestions,
            zoomScope: web.zoomScope == .site ? .site : (web.zoomScope == .session ? .session : .page),
            textOnlyZoom: web.textOnlyZoom
        )
        settings.agent = BrowserAgent(rawValue: web.agent.rawValue) ?? .safari
        settings.agentScripts = web.agentScripts
        settings.notificationAskWithoutClick = web.notificationsWithoutClick
        settings.workerNotifications = web.workerNotifications
        settings.blocking = web.blocking
        return settings
    }

    /// The settings for what the command bar opens or suggests in `tabs`: private in a private window, or when its shown page is private.
    static func webSettings(for tabs: TabsModel) -> WebSettings {
        let own = ownProfile(of: tabs)
        var settings = webSettings
        if let own, !own.overrides.isEmpty {
            // Its profile's own values over all profiles' (roadmap 0050).
            let web = ProfileOverrides.apply(own.overrides, to: AppConfiguration.shared.configuration).web
            settings = webSettings(from: web)
            settings.proxy = WebProxy(web.proxy)
            settings.permissionDefaults = AppDownloads.permissionDefaults(web)
            settings.downloadFolder = AppDownloads.folder(web)
            settings.askWhereToSave = web.askWhereToSave
        }
        settings.profile = profile(of: tabs)
        if let page = tabs.selectedContent as? WebContent, page.isPrivate {
            settings.privacy = page.settings.privacy
        } else if let group = tabs.privateGroup {
            settings.privacy = PagePrivacy(group: group)
        }
        return settings
    }

    /// An empty private page (File > New Private Tab).
    static let newPrivatePage = PaneDescriptor(kind: WebContent.kind, state: ["private": "1"])

    /// Read once: the installed Safari's version does not change while the app runs (or if it does, the next launch reads it).
    private static let safariName = SafariName.applicationName()

    /// A new empty page, asking for an address.
    static let newPage = PaneDescriptor(kind: WebContent.kind)

    static func isDirectory(_ path: String) -> Bool {
        var isDirectory: ObjCBool = false
        return FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory) && isDirectory.boolValue
    }

    /// The profile whose website data a page made in `tabs` uses: its Space's; nil for the first, and for a window that
    /// is not among the app's Spaces.
    static func ownProfile(of tabs: TabsModel) -> Profile? {
        guard AppSpaces.all.contains(tabs.space) else { return nil }
        return AppSpaces.all.profiles.profile(of: tabs.space.space).profile
    }

    static func profile(of tabs: TabsModel) -> UUID? {
        guard AppSpaces.all.contains(tabs.space) else { return nil }
        let profile = AppSpaces.all.profiles.profile(of: tabs.space.space).profile
        return profile.isFirst ? nil : profile.id
    }
}
