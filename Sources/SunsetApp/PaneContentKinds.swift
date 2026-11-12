import Foundation
import SunsetConfig
import SunsetPane
import SunsetShell
import SunsetWeb

/// The kinds of content besides the terminal (which the scene makes, with its configuration): what a saved descriptor becomes.
@MainActor enum PaneContentKinds {
    /// The content `descriptor` says; a kind this build does not have is kept as a placeholder. `changed` is called when the content has something
    /// new to save.
    static func make(_ descriptor: PaneDescriptor, privacy: PagePrivacy? = nil, changed: @escaping () -> Void)
        -> any PaneContent
    {
        switch descriptor.kind {
            case WebContent.kind:
                var settings = webSettings
                settings.privacy = privacy ?? (descriptor.state["private"] == "1" ? PagePrivacy() : nil)
                let page = WebContent(descriptor: descriptor, settings: settings)
                page.onChange = changed
                return page
            case NoteContent.kind:
                let note = NoteContent(text: descriptor.state["text"] ?? "")
                note.onEdit = changed
                return note
            default:
                return UnknownContent(descriptor)
        }
    }

    /// What pages are made with, from `web.*`.
    static var webSettings: WebSettings {
        let web = AppConfiguration.shared.configuration.web
        let added = web.engines.map {
            SearchEngine(name: $0.name, keyword: $0.keyword, search: $0.search, suggest: $0.suggest)
        }
        return WebSettings(
            applicationName: safariName,
            developer: web.developer,
            initialIcon: web.tabIcon == .initial,
            engines: WebSettings.engines(adding: added),
            engine: web.engine,
            suggestions: web.suggestions,
            httpFallback: web.httpFallback,
            privateSuggestions: web.privateSuggestions,
            zoomScope: web.zoomScope == .site ? .site : (web.zoomScope == .session ? .session : .page),
            textOnlyZoom: web.textOnlyZoom
        )
    }

    /// The settings for what the command bar opens or suggests in `tabs`: private in a private window, or when its shown page is private.
    static func webSettings(for tabs: TabsModel) -> WebSettings {
        var settings = webSettings
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
}
