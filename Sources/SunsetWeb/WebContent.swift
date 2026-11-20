package import Foundation
package import Observation
package import SunsetPane
import SunsetPrivate
package import SunsetRuntime
package import SunsetShell
package import SwiftUI
package import WebKit

/// A web page as the content of a pane (R1, web step a): the system's WebKit, named as Safari; made the first time it is shown; the default persistent
/// store; brought back with its address, history and scroll. Pages it opens (a link asking for a new tab, the link menu) are handed to `onOpen`, which
/// places them.
@MainActor @Observable
package final class WebContent: PaneContent, PaneViewMaking {
    /// Where its tasks run, the clock it waits on, the time it reads (ADR-0087); `.live` unless a test sets another.
    @ObservationIgnored package var runtime = Runtime.live

    package static let kind = "web"

    package internal(set) var url: URL?
    package internal(set) var pageTitle = ""
    package internal(set) var progress: Double?
    package var failure: WebFailure?
    package internal(set) var canGoBack = false
    package internal(set) var canGoForward = false
    package internal(set) var isLoading = false
    /// The page asks for its address to be typed (a new empty page): the address field of the window takes the keyboard and clears this.
    package var wantsAddress = false
    @ObservationIgnored var forcing = false  // Its process ended on purpose (a force reload): not a crash to show.
    /// The site's settings are open beside its address field (its lock, or the field's menu: roadmap 0047 F).
    package var showsSiteSettings = false
    package internal(set) var permissionRequest: PermissionRequest?  // Waiting under the address (web step g).
    /// What the page captures now: the camera or microphone, the screen (shown as a dot on its tab and in its address field).
    package internal(set) var capture: PageCapture?
    package internal(set) var devices = PaneCapture()  // The microphone and the camera, each live or muted (n47).
    package let find = PageFind()  // Find in the page (Cmd-F).
    package internal(set) var zoom = 1.0  // 1 for 100% (Cmd-+, Cmd--, Cmd-0; `WebContent+Zoom`).
    /// The site's icon, once fetched (`WebContent+Favicon`).
    package internal(set) var favicon: NSImage? {
        didSet {
            if favicon !== oldValue {
                iconColor = favicon.flatMap(Self.colour)
                faviconPicture = favicon?.panePicture
            }
        }
    }
    /// The icon as the tab's picture, made once for each icon (`glyph` is read at every drawing).
    @ObservationIgnored var faviconPicture: PanePicture?
    package internal(set) var pageBackground: NSColor?
    /// The colours the site declares (`<meta name="theme-color">`) and its icon has, as sRGB bytes (roadmap 0047 H).
    package internal(set) var themeColor: [UInt8]?
    package internal(set) var iconColor: [UInt8]?
    /// The dialog the page asked for, waiting for its answer (`WebContent+Dialogs`).
    package internal(set) var dialog: PageDialog?
    /// Sharing (ADR-0082): a tab asked for (the sheet shows it), the tab shared into this page, the calls it is shared into.
    package internal(set) var shareRequest: ShareRequest?
    package internal(set) var share: ShareSession?
    package internal(set) var reloadedAs: OtherProfile?  // Reload as (roadmap 0050 D), and its Space's:
    @ObservationIgnored var homeProfile: OtherProfile?
    @ObservationIgnored var shareWrapper: ShareWrapper?
    @ObservationIgnored var dialogPolicy = PageDialogPolicy()
    /// A server's question for a name and a password, waiting (`CredentialRequest`).
    package internal(set) var credentialRequest: CredentialRequest?
    /// The page plays sound; it is muted (roadmap 0029 step 7).
    package internal(set) var playsSound = false
    package internal(set) var isMuted = false
    @ObservationIgnored var soundWatch: NSObject?
    /// The address of the link under the pointer (`LinkStatus`).
    package internal(set) var hoveredLink: String?
    /// The page, once it has been shown.
    @ObservationIgnored package internal(set) var webView: WKWebView?
    /// The page's last snapshot (`takePicture`).
    package internal(set) var picture: CGImage?
    /// When a title change last asked for a picture (seconds of uptime).
    @ObservationIgnored var lastTitlePicture: Double?
    /// When the page was last pictured again for a change of its text (roadmap 0042 D).
    @ObservationIgnored var lastTextPicture: Double?
    /// A snapshot was asked for and has not arrived.
    @ObservationIgnored package internal(set) var takingPicture = false
    /// It was on screen at the last `setState`.
    @ObservationIgnored var shown = false
    /// Since when it is not on screen, once it was made (S-f): what decides when it is unloaded.
    @ObservationIgnored package internal(set) var hiddenSince: Date?
    /// Its view was let go of to free memory (S-f): it is made again, where it was, when it is shown. Its icon is dimmed.
    package internal(set) var isUnloaded = false

    package var onExit: () -> Void = {}
    package var onFocusRequest: () -> Void = {}
    /// Where the sites' icons are kept (roadmap 0035 H): the app's; a test gives its own.
    @ObservationIgnored package var icons = FaviconStore.shared
    /// When the page last changed its icon (seconds of uptime): followed once a second at most.
    @ObservationIgnored var lastIconChange: Double?
    /// A notification the page may show, to post (roadmap 0035 D).
    @ObservationIgnored package var onNotify: (WebNotification) -> Void = { _ in }
    /// The page took a notification of its own away (`close()`, roadmap 0036 E).
    @ObservationIgnored package var onNotificationClose: (Int) -> Void = { _ in }
    /// When it last showed one (seconds of uptime): one a second at most.
    @ObservationIgnored var lastNotification: Double?
    /// Sites allowed to notify once, for this page's life (Allow Once).
    @ObservationIgnored var notificationHosts: Set<String> = []
    /// A notification question of this page is shown: another asked meanwhile is answered at once.
    @ObservationIgnored var notificationAsking = false
    @ObservationIgnored let notificationClicks = NotificationClicks()
    /// A page this one opened, and where it goes.
    @ObservationIgnored package var onOpen: (WebContent, WebPlacement) -> Void = { _, _ in }
    /// The Space it is in, and the Spaces a site can be sent to (W-d): the app's; none in a test or a private window.
    @ObservationIgnored package var currentSpace: () -> UUID? = { nil }
    @ObservationIgnored package var spaceChoices: () -> [(id: UUID, name: String)] = { [] }
    /// Opens `url` in the Space `id`, as the site's rule says (W-d).
    @ObservationIgnored package var openInSpace: (URL, UUID) -> Void = { _, _ in }
    /// The history visits are written to (web step e); nil keeps none (tests, and private pages in step h).
    @ObservationIgnored package var history: HistoryStore?
    /// Something the session file holds changed (the address, the title).
    @ObservationIgnored package var onChange: () -> Void = {}

    /// Followed when the configuration changes (`TerminalScene`); the engine, suggestions and http fallback apply at once.
    @ObservationIgnored package var settings: WebSettings
    /// The browser each site is shown (W-a): the app's rules; a test gives its own.
    @ObservationIgnored package var agents = SiteAgents.shared
    @ObservationIgnored var savedHistory: Data?
    @ObservationIgnored var observations: [NSKeyValueObservation] = []
    @ObservationIgnored var coordinator: WebCoordinator?
    /// Hosts whose untrusted certificate the person chose to accept, for this page (Visit Anyway).
    @ObservationIgnored var acceptedHosts: Set<String> = []
    /// Hosts the person chose to load over http on this page, HTTPS having failed ("ask", `web.httpsUpgrade`).
    @ObservationIgnored var httpHosts: Set<String> = []
    /// The size the page that opened it asked for, as a pop-up (`window.open` with a width): its window's (task t132).
    @ObservationIgnored package var popupSize: CGSize?
    /// It, as its profile's extensions see a tab (roadmap 0109 B).
    @ObservationIgnored var extensionTab: ExtensionTab?
    /// A private page's answers, in memory for its life (web step h).
    @ObservationIgnored var ownPermissions: SitePermissions?
    /// The host last typed without a scheme while the http setting is on: if https fails for it, http is tried (`WebCoordinator`).
    @ObservationIgnored var fallbackHost: String?
    /// What the person last asked this page for (roadmap 0045 F): loaded again when its site is shown another browser.
    @ObservationIgnored var asked = AskedAddress()

    /// A page to open at `url` (nil: an empty page that asks for an address), with what brings its history back.
    package init(url: URL?, title: String = "", history: Data? = nil, settings: WebSettings) {
        self.url = url
        pageTitle = title
        savedHistory = history
        self.settings = settings
    }

    /// A page WebKit asks for (a link opening a new tab): it must be made at once with WebKit's own configuration, which ties it to its opener.
    init(configuration: WKWebViewConfiguration, settings: WebSettings) {
        self.settings = settings
        makeWebView(configuration: configuration)
    }

    /// A saved page: its address, its title, its history (base64).
    package convenience init(descriptor: PaneDescriptor, settings: WebSettings) {
        let history = descriptor.state["history"].flatMap { Data(base64Encoded: $0) }
        self.init(
            url: descriptor.state["url"].flatMap(URL.init(string:)),
            title: descriptor.state["title"] ?? "",
            history: history,
            settings: settings
        )
        zoom = descriptor.state["zoom"].flatMap(Double.init) ?? 1
        if let other = Self.savedProfile(descriptor.state["as"]) { takeProfile(other.id) }
        // Not loaded until it is shown or pointed at (roadmap 0047 I).
        isUnloaded = url != nil
    }

    // MARK: PaneContent

    package var descriptor: PaneDescriptor {
        var state: [String: String] = [:]
        if let url { state["url"] = url.absoluteString }
        if !pageTitle.isEmpty { state["title"] = pageTitle }
        if settings.zoomScope == .page, abs(zoom - 1) > 0.001 { state["zoom"] = String(zoom) }
        if isPrivate { state["private"] = "1" }
        if let reloadedAs { state["as"] = reloadedAs.id?.uuidString ?? "first" }
        if let history = (webView?.interactionState as? Data) ?? savedHistory {
            state["history"] = history.base64EncodedString()
        }
        return PaneDescriptor(kind: Self.kind, state: state)
    }

    package func setState(focused: Bool, visible: Bool) {
        if visible, webView == nil { makeWebView(configuration: nil) }
        if visible { isUnloaded = false }
        // Hidden: its last picture is taken while it is still drawn, for its tab's preview (roadmap 0035 C).
        if !visible, shown { takePicture() }
        if visible { hiddenSince = nil } else if hiddenSince == nil, webView != nil { hiddenSince = runtime.now() }
        shown = visible
    }

    /// Its row is pointed at (note n1): a page not made yet is made and starts loading, drawn by the time it is shown.
    package func prepare() {
        if webView == nil { makeWebView(configuration: nil) }
    }

    /// A snapshot of the page as it is drawn now (roadmap 0035 C, J): kept as its `picture` when it arrives.
    package func takePicture() {
        guard let webView, webView.window != nil, webView.bounds.width > 0, webView.bounds.height > 0 else { return }
        takingPicture = true
        webView.takeSnapshot(with: nil) { [weak self] image, _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                self.takingPicture = false
                if let image { self.picture = image.cgImage(forProposedRect: nil, context: nil, hints: nil) }
            }
        }
    }

    package func stop() {
        dialog?.answer(.cancel)
        credentialRequest?.answer(nil)
        endView(keepingHistory: false)
    }

    package func makeView(_ context: PaneViewContext) -> AnyView {
        if webView == nil { makeWebView(configuration: nil) }
        return AnyView(
            WebPaneView(content: self, focused: context.focused, topInset: context.topInset, backdrop: context.backdrop)
        )
    }
}
