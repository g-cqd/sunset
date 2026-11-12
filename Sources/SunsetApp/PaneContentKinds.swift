import Foundation
import SunsetConfig
import SunsetPane
import SunsetShell
import SunsetWeb

/// The kinds of content besides the terminal (which the scene makes, with its configuration): what a saved descriptor becomes.
@MainActor enum PaneContentKinds {
    /// The content `descriptor` says; a kind this build does not have is kept as a placeholder. `changed` is called when the content has something
    /// new to save.
    static func make(_ descriptor: PaneDescriptor, changed: @escaping () -> Void) -> any PaneContent {
        switch descriptor.kind {
            case WebContent.kind:
                let page = WebContent(descriptor: descriptor, settings: webSettings)
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
            zoomScope: web.zoomScope == .site ? .site : (web.zoomScope == .session ? .session : .page),
            textOnlyZoom: web.textOnlyZoom
        )
    }

    /// Read once: the installed Safari's version does not change while the app runs (or if it does, the next launch reads it).
    private static let safariName = SafariName.applicationName()

    /// A new empty page, asking for an address.
    static let newPage = PaneDescriptor(kind: WebContent.kind)

    static func isDirectory(_ path: String) -> Bool {
        var isDirectory: ObjCBool = false
        return FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory) && isDirectory.boolValue
    }
}
