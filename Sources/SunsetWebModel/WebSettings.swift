package import Foundation

/// What a page is made with, from the app's configuration (`web.*`).
package struct WebSettings: Sendable, Equatable {
    /// The end of the user agent (`SafariName`).
    package var applicationName: String
    /// The inspector can be opened.
    package var developer: Bool
    /// The tab shows the first letter of the title (true) or a globe.
    package var initialIcon: Bool
    /// The tab shows the site's icon once it is known (the initial until then).
    package var favicons = true
    /// Pages render at the screen's rate, not near 60 fps (`web.fullFrameRate`).
    package var fullFrameRate = true
    /// The engines that can be picked by keyword, built-in and added.
    package var engines: [SearchEngine]
    /// The one words are searched with.
    package var engine: SearchEngine
    package var suggestions: Bool
    package var httpsUpgrade = HTTPSUpgrade.fallback
    /// Which pop-ups open in a pop-up window (`web.popupWindows`).
    package var popupWindows = PopupWindows.sized
    package var hardening = Hardening.off
    package var globalPrivacyControl = GlobalPrivacyControl.privateWindows
    package var zoomScope: ZoomScope
    package var textOnlyZoom: Bool
    /// A private page's store; nil for a page of the persistent store. Pages it opens inherit it.
    package var privacy: PagePrivacy?
    /// The profile whose website data the page uses; nil: the first profile's, the store there always was.
    package var profile: UUID?
    /// Suggestions while typing in a private page (`web.privateSuggestions`).
    package var privateSuggestions = false
    /// The browser a site with no rule of its own is shown (`web.agent`): Safari is Sunset as it is.
    package var agent = BrowserAgent.safari
    /// What a page's scripts read to tell a browser is set too (`web.agentScripts`): the second rung.
    package var agentScripts = true
    /// A page's request to notify asks the person without a click too (`web.notificationsWithoutClick`, as Chrome); off,
    /// it is answered by the site's answer as it stands (Safari).
    package var notificationAskWithoutClick = false
    /// A page's `registration.showNotification(…)` is posted as its own are (`web.workerNotifications`).
    package var workerNotifications = true
    /// What its profile sets otherwise than all profiles, or all profiles' own: blocking, the proxy its store is given,
    /// what a site gets until answered, where a download goes and whether it is asked.
    package var blocking = true
    package var proxy: WebProxy?
    package var permissionDefaults: [SitePermission: PermissionAnswer]?
    package var downloadFolder: URL?
    package var askWhereToSave: Bool?

    /// Whether what is typed is sent for suggestions: `suggestions`, or for a private page `privateSuggestions`.
    package var suggestsWhileTyping: Bool {
        privacy == nil ? suggestions : privateSuggestions
    }
    /// Sunset runs as Sunset.app, with the usage strings macOS needs before a page may use the camera, the microphone or location.
    package var hasAppIdentity = Bundle.main.object(forInfoDictionaryKey: "NSCameraUsageDescription") != nil
    /// Pages have `navigator.mediaDevices`. WebKit turns it on for an app that says why it asks for the camera, and for
    /// another only while that app holds an answer (observed 2026-11-19: a test run lost it when Sunset's signature changed
    /// and its answers were not yet given again); tests ask for it plainly.
    package var mediaDevices = Bundle.main.object(forInfoDictionaryKey: "NSCameraUsageDescription") != nil

    /// What a page's zoom applies to (`web.zoomScope`).
    package enum ZoomScope: Sendable, Equatable { case site, session, page }

    package init(
        applicationName: String = SafariName.applicationName(),
        developer: Bool = true,
        initialIcon: Bool = true,
        favicons: Bool = true,
        fullFrameRate: Bool = true,
        engines: [SearchEngine] = SearchEngine.builtIn,
        engine: String = "Google",
        suggestions: Bool = true,
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
        self.favicons = favicons
        self.fullFrameRate = fullFrameRate
        self.engines = engines
        self.engine =
            engines.first { $0.name.lowercased() == engine.lowercased() } ?? engines.first ?? SearchEngine.builtIn[0]
        self.suggestions = suggestions
    }

    /// What Sunset says it is in the requests it makes without a page (search suggestions): the default browser's
    /// User-Agent; for Safari, what WebKit says by itself on a Mac, with the installed Safari's version.
    package var userAgent: String {
        agent.userAgent
            ?? "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) "
            + applicationName
    }

    /// What `typed` means with these engines.
    package func input(_ typed: String) -> WebInput? {
        WebInput.parse(typed, engine: engine, engines: engines)
    }

    /// The built-in engines with the added ones: one with a built-in name replaces it, the others follow.
    package static func engines(adding added: [SearchEngine]) -> [SearchEngine] {
        let names = Set(added.map { $0.name.lowercased() })
        return SearchEngine.builtIn.filter { !names.contains($0.name.lowercased()) } + added
    }
}
