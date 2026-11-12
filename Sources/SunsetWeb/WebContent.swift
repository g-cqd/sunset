package import Foundation
package import Observation
package import SunsetPane
import SunsetPrivate
package import SunsetShell
package import SwiftUI
package import WebKit

/// A web page as the content of a pane (R1, web step a): the system's WebKit, named as Safari; made the first time it is shown; the default persistent
/// store; brought back with its address, history and scroll. Pages it opens (a link asking for a new tab, the link menu) are handed to `onOpen`, which
/// places them.
@MainActor @Observable
package final class WebContent: PaneContent {
    package static let kind = "web"

    package private(set) var url: URL?
    package private(set) var pageTitle = ""
    package private(set) var progress: Double?
    package var failure: WebFailure?
    package private(set) var canGoBack = false
    package private(set) var canGoForward = false
    package private(set) var isLoading = false
    /// The page asks for its address to be typed (a new empty page): the address field of the window takes the keyboard and clears this.
    package var wantsAddress = false
    /// Find in the page (Cmd-F).
    package let find = PageFind()
    /// The page's zoom, 1 for 100% (Cmd-+, Cmd--, Cmd-0; `WebContent+Zoom`).
    package internal(set) var zoom = 1.0
    /// The page, once it has been shown.
    @ObservationIgnored package private(set) var webView: WKWebView?

    package var onExit: () -> Void = {}
    package var onFocusRequest: () -> Void = {}
    /// A page this one opened, and where it goes.
    @ObservationIgnored package var onOpen: (WebContent, WebPlacement) -> Void = { _, _ in }
    /// The history visits are written to (web step e); nil keeps none (tests, and private pages in step h).
    @ObservationIgnored package var history: HistoryStore?
    /// Something the session file holds changed (the address, the title).
    @ObservationIgnored package var onChange: () -> Void = {}

    /// Followed when the configuration changes (`TerminalScene`); the engine, suggestions and http fallback apply at once.
    @ObservationIgnored package var settings: WebSettings
    @ObservationIgnored private var savedHistory: Data?
    @ObservationIgnored private var observations: [NSKeyValueObservation] = []
    @ObservationIgnored private var coordinator: WebCoordinator?
    /// Hosts whose untrusted certificate the person chose to accept, for this page (Visit Anyway).
    @ObservationIgnored var acceptedHosts: Set<String> = []
    /// The host last typed without a scheme while the http setting is on: if https fails for it, http is tried (`WebCoordinator`).
    @ObservationIgnored var fallbackHost: String?

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
    }

    // MARK: PaneContent

    package var title: String { pageTitle.isEmpty ? (url?.host() ?? "New Page") : pageTitle }
    /// No second line in a tab: the address is in the address field (owner note n62); the address is still searched by (`searchTerms`).
    package var detail: String? { nil }
    package var searchTerms: [String] { url.map { [$0.absoluteString] } ?? [] }
    package var closeWarning: String? { nil }

    package var glyph: PaneGlyph {
        guard settings.initialIcon, let first = title.first(where: \.isLetter) else { return .symbol("globe") }
        return .initial(String(first).uppercased())
    }

    package var descriptor: PaneDescriptor {
        var state: [String: String] = [:]
        if let url { state["url"] = url.absoluteString }
        if !pageTitle.isEmpty { state["title"] = pageTitle }
        if settings.zoomScope == .page, abs(zoom - 1) > 0.001 { state["zoom"] = String(zoom) }
        if let history = (webView?.interactionState as? Data) ?? savedHistory {
            state["history"] = history.base64EncodedString()
        }
        return PaneDescriptor(kind: Self.kind, state: state)
    }

    package func setState(focused: Bool, visible: Bool) {
        if visible, webView == nil { makeWebView(configuration: nil) }
    }

    package func stop() {
        observations = []
        webView?.stopLoading()
        webView?.navigationDelegate = nil
        webView?.uiDelegate = nil
        webView = nil
    }

    package func makeView(_ context: PaneViewContext) -> AnyView {
        if webView == nil { makeWebView(configuration: nil) }
        return AnyView(WebPaneView(content: self, focused: context.focused, topInset: context.topInset))
    }

    // MARK: Navigating

    /// Opens what was typed: an address, or a search with the engine it names or the chosen one.
    package func open(typed: String) {
        guard let input = settings.input(typed) else { return }
        open(input)
    }

    package func open(_ input: WebInput) {
        guard let address = input.url else { return }
        if case .address(_, let guessed) = input, guessed, settings.httpFallback { fallbackHost = address.host() }
        load(address)
    }

    package func load(_ address: URL) {
        url = address
        failure = nil
        if webView == nil { makeWebView(configuration: nil) }
        webView?.load(URLRequest(url: address))
        onChange()
    }

    /// Loads the page again; `fromOrigin`: without what the cache holds (Shift-Cmd-R).
    package func reload(fromOrigin: Bool = false) {
        failure = nil
        if let url, webView?.url == nil {
            webView?.load(URLRequest(url: url))
        } else if fromOrigin {
            webView?.reloadFromOrigin()
        } else {
            webView?.reload()
        }
    }

    /// Visit Anyway: the certificate of this host is accepted for this page, and the page is loaded again.
    package func acceptCertificate() {
        guard let host = failure?.url?.host() else { return }
        acceptedHosts.insert(host)
        if let address = failure?.url { load(address) }
    }

    // MARK: The view

    private func makeWebView(configuration given: WKWebViewConfiguration?) {
        let configuration = given ?? WKWebViewConfiguration()
        if given == nil { configuration.websiteDataStore = .default() }
        configuration.applicationNameForUserAgent = settings.applicationName
        WebDeveloperExtras.set(settings.developer, on: configuration.preferences)
        let view = SunsetWebView(frame: .zero, configuration: configuration)
        view.isInspectable = settings.developer
        view.allowsBackForwardNavigationGestures = true
        view.onFocus = { [weak self] in self?.onFocusRequest() }
        let coordinator = WebCoordinator(content: self)
        view.navigationDelegate = coordinator
        view.uiDelegate = coordinator
        self.coordinator = coordinator
        webView = view
        find.attach(view)
        applyZoom()
        observe(view)
        guard given == nil else { return }
        if let history = savedHistory {
            view.interactionState = history as NSData
            savedHistory = nil
        }
        if view.url == nil, let url { view.load(URLRequest(url: url)) }
        if url == nil, view.url == nil { wantsAddress = true }
    }

    private func observe(_ view: WKWebView) {
        observations = [
            view.observe(\.title, options: [.new]) { [weak self] view, _ in
                MainActor.assumeIsolated { self?.changed(title: view.title) }
            },
            view.observe(\.url, options: [.new]) { [weak self] view, _ in
                MainActor.assumeIsolated { self?.changed(url: view.url) }
            },
            view.observe(\.estimatedProgress, options: [.new]) { [weak self] view, _ in
                MainActor.assumeIsolated { self?.progress = view.isLoading ? view.estimatedProgress : nil }
            },
            view.observe(\.isLoading, options: [.new]) { [weak self] view, _ in
                MainActor.assumeIsolated {
                    self?.isLoading = view.isLoading
                    if !view.isLoading { self?.progress = nil }
                }
            },
            view.observe(\.canGoBack, options: [.new]) { [weak self] view, _ in
                MainActor.assumeIsolated { self?.canGoBack = view.canGoBack }
            },
            view.observe(\.canGoForward, options: [.new]) { [weak self] view, _ in
                MainActor.assumeIsolated { self?.canGoForward = view.canGoForward }
            }
        ]
    }

    private func changed(title: String?) {
        guard let title, title != pageTitle else { return }
        pageTitle = title
        if let address = webView?.url?.absoluteString { history?.retitle(address, title: title) }
        onChange()
    }

    private func changed(url new: URL?) {
        guard let new, new != url else { return }
        let otherSite = new.host() != url?.host()
        url = new
        if otherSite { siteChanged() }
        onChange()
    }
}
