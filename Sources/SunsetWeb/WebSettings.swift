import Foundation

/// What a page is made with, from the app's configuration (`web.*`).
package struct WebSettings: Sendable, Equatable {
    /// The end of the user agent (`SafariName`).
    package var applicationName: String
    /// The inspector can be opened.
    package var developer: Bool
    /// The tab shows the first letter of the title (true) or a globe.
    package var initialIcon: Bool
    /// The engines that can be picked by keyword, built-in and added (web step c).
    package var engines: [SearchEngine]
    /// The one words are searched with.
    package var engine: SearchEngine
    package var suggestions: Bool
    package var httpFallback: Bool
    package var zoomScope: ZoomScope
    package var textOnlyZoom: Bool
    /// A private page's store (web step h); nil for a page of the persistent store. Pages it opens inherit it.
    package var privacy: PagePrivacy?
    /// Suggestions while typing in a private page (`web.privateSuggestions`).
    package var privateSuggestions = false

    /// Whether what is typed is sent for suggestions: `suggestions`, or for a private page `privateSuggestions`.
    package var suggestsWhileTyping: Bool { privacy == nil ? suggestions : privateSuggestions }
    /// Sunset runs as Sunset.app, with the usage strings macOS needs before a page may use the camera, the microphone or location.
    package var hasAppIdentity = Bundle.main.object(forInfoDictionaryKey: "NSCameraUsageDescription") != nil

    /// What a page's zoom applies to (`web.zoomScope`).
    package enum ZoomScope: Sendable, Equatable { case site, session, page }

    package init(
        applicationName: String = SafariName.applicationName(),
        developer: Bool = true,
        initialIcon: Bool = true,
        engines: [SearchEngine] = SearchEngine.builtIn,
        engine: String = "Google",
        suggestions: Bool = true,
        httpFallback: Bool = false,
        privateSuggestions: Bool = false,
        zoomScope: ZoomScope = .site,
        textOnlyZoom: Bool = false
    ) {
        self.privateSuggestions = privateSuggestions
        self.zoomScope = zoomScope
        self.textOnlyZoom = textOnlyZoom
        self.applicationName = applicationName
        self.developer = developer
        self.initialIcon = initialIcon
        self.engines = engines
        self.engine =
            engines.first { $0.name.lowercased() == engine.lowercased() } ?? engines.first ?? SearchEngine.builtIn[0]
        self.suggestions = suggestions
        self.httpFallback = httpFallback
    }

    /// What `typed` means with these engines.
    package func input(_ typed: String) -> WebInput? { WebInput.parse(typed, engine: engine, engines: engines) }

    /// The built-in engines with the added ones: one with a built-in name replaces it, the others follow.
    package static func engines(adding added: [SearchEngine]) -> [SearchEngine] {
        let names = Set(added.map { $0.name.lowercased() })
        return SearchEngine.builtIn.filter { !names.contains($0.name.lowercased()) } + added
    }
}
