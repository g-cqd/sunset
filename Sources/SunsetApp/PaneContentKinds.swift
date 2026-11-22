import Foundation
import SunsetAppCore
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
                // Its Space's profile's settings; a page saved as another profile takes that one's as it is made (`as`).
                let settings = pageSettings(
                    profile: profile,
                    privacy: privacy ?? (descriptor.state["private"] == "1" ? PagePrivacy() : nil)
                )
                let page = WebContent(descriptor: descriptor, settings: settings)
                page.onChange = changed
                return page
            case DocumentContent.kind:
                // One that names no document is kept as it was written.
                guard let document = DocumentContent(descriptor, documents: SunsetStore.shared.openDocuments) else {
                    return UnknownContent(descriptor)
                }
                document.onChange = changed
                return document
            case SettingsContent.kind:
                let settings = SettingsContent(descriptor)
                settings.onChange = changed
                return settings
            case PasswordsContent.kind:
                let passwords = PasswordsContent()
                passwords.onChange = changed
                return passwords
            case HelpContent.kind:
                let help = HelpContent(descriptor)
                help.onChange = changed
                return help
            default:
                return UnknownContent(descriptor)
        }
    }

    /// What pages are made with, from `web.*`.
    static var webSettings: WebSettings {
        webSettings(from: AppConfiguration.shared.configuration.web)
    }

    /// A page's settings from a configuration's (all profiles', or one profile's with its own values).
    static func webSettings(from web: Configuration.Web) -> WebSettings {
        maker.settings(from: web)
    }

    /// The pages' settings, made outside the app target (`SunsetAppCore`).
    static let maker = PageSettingsMaker(applicationName: safariName)

    /// The settings for what the command bar opens or suggests in `tabs`: private in a private window, or when its shown page is private.
    static func webSettings(for tabs: TabsModel) -> WebSettings {
        let privacy: PagePrivacy? =
            if let page = tabs.selectedContent as? WebContent, page.isPrivate {
                page.settings.privacy
            } else {
                tabs.privateGroup.map { PagePrivacy(group: $0) }
            }
        return pageSettings(profile: profile(of: tabs), privacy: privacy)
    }

    /// A page's settings, the one way they are made (every page made, Reload As, a change of settings): its profile's own
    /// values over all profiles', its profile (nil: the first), its privacy. Before, four places each made them, and one
    /// that forgot the profile or its own values sent a page to another profile's settings.
    static func pageSettings(profile id: UUID?, privacy: PagePrivacy?) -> WebSettings {
        let own = AppSpaces.all.profiles.profiles.map(\.profile).first { ($0.isFirst ? nil : $0.id) == id }
        var settings = webSettings(of: own)
        settings.profile = id
        settings.privacy = privacy
        return settings
    }

    /// A profile's page settings: its own values over all profiles'; nil: all profiles'.
    private static func webSettings(of own: Profile?) -> WebSettings {
        maker.settings(app: AppConfiguration.shared.configuration, own: own)
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

    /// The profile of the Space `tabs` shows (nil: the first, and a window not among the app's Spaces).
    static func profile(of tabs: TabsModel) -> UUID? {
        guard AppSpaces.all.contains(tabs.space) else { return nil }
        return profile(ofSpace: tabs.space)
    }

    /// The profile of `space` (the first profile: nil).
    static func profile(ofSpace space: SpaceModel) -> UUID? {
        let profile = AppSpaces.all.profiles.profile(of: space.space).profile
        return profile.isFirst ? nil : profile.id
    }
}
