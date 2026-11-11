import Observation
import SunsetPane
import SwiftUI
import WebKit

/// A web page in a pane, on the system's WebKit. Everything that is WebKit's is in this file and the views beside it: the shell sees a `PaneContent`,
/// so another engine can take its place (docs/research/shell-extraction-2026-11-11.md, t119). The page is made when it is first shown: a tab restored
/// and never looked at loads nothing.
@MainActor @Observable
final class WebContent: NSObject, PaneContent {
    static let kind = "web"
    /// As Safari names itself: a page that sees only "AppleWebKit" serves its oldest layout (seen with Google; the Search browser's finding).
    private static let agentName = "Version/26.0 Safari/605.1.15"

    private(set) var address: URL?
    private(set) var pageTitle = ""
    private(set) var loading: Double?
    private(set) var canGoBack = false
    private(set) var canGoForward = false
    /// What the address field shows: the page's address, or what is being typed.
    var typed = ""
    @ObservationIgnored var onExit: () -> Void = {}
    @ObservationIgnored var onFocusRequest: () -> Void = {}
    /// The address changed: the session is to be saved.
    @ObservationIgnored var onNavigate: () -> Void = {}
    @ObservationIgnored private var page: WebPageView?
    @ObservationIgnored private var watches: [NSKeyValueObservation] = []

    init(address: URL?) {
        self.address = address
        typed = address?.absoluteString ?? ""
    }

    var title: String { pageTitle.isEmpty ? (address?.host() ?? "New Page") : pageTitle }
    var detail: String? { address?.host() }
    var glyph: PaneGlyph { .symbol("globe") }
    var progress: Double? { loading }
    /// A page can always be closed: what is typed in a form is the page's to warn about, not asked here yet.
    var closeWarning: String? { nil }
    var descriptor: PaneDescriptor {
        PaneDescriptor(kind: Self.kind, state: address.map { ["url": $0.absoluteString] } ?? [:])
    }

    func setState(focused: Bool, visible: Bool) {}

    func stop() {
        watches.removeAll()
        page?.stopLoading()
        page = nil
    }

    func makeView(_ context: PaneViewContext) -> AnyView {
        AnyView(WebPaneView(content: self, focused: context.focused).padding(.top, context.topInset))
    }

    /// The page's view, made at the first call and loading the saved address.
    func view() -> WebPageView {
        if let page { return page }
        let configuration = WKWebViewConfiguration()
        configuration.applicationNameForUserAgent = Self.agentName
        configuration.preferences.isElementFullscreenEnabled = true
        let made = WebPageView(frame: .zero, configuration: configuration)
        made.isInspectable = true
        made.allowsBackForwardNavigationGestures = true
        made.uiDelegate = self
        made.onFocus = { [weak self] in self?.onFocusRequest() }
        page = made
        watch(made)
        if let address { made.load(URLRequest(url: address)) }
        return made
    }

    /// Loads what was typed in the address field (`WebAddress`).
    func go() {
        guard let url = WebAddress.url(for: typed) else { return }
        view().load(URLRequest(url: url))
    }

    func back() { page?.goBack() }
    func forward() { page?.goForward() }
    func reload() { if loading == nil { page?.reload() } else { page?.stopLoading() } }

    private func watch(_ page: WebPageView) {
        // WebKit changes these on the main thread.
        watches = [
            page.observe(\.title) { [weak self] page, _ in
                MainActor.assumeIsolated { self?.pageTitle = page.title ?? "" }
            },
            page.observe(\.url) { [weak self] page, _ in MainActor.assumeIsolated { self?.moved(to: page.url) } },
            page.observe(\.estimatedProgress) { [weak self] page, _ in
                MainActor.assumeIsolated { self?.loading = page.isLoading ? page.estimatedProgress : nil }
            },
            page.observe(\.isLoading) { [weak self] page, _ in
                MainActor.assumeIsolated { self?.loading = page.isLoading ? page.estimatedProgress : nil }
            },
            page.observe(\.canGoBack) { [weak self] page, _ in
                MainActor.assumeIsolated { self?.canGoBack = page.canGoBack }
            },
            page.observe(\.canGoForward) { [weak self] page, _ in
                MainActor.assumeIsolated { self?.canGoForward = page.canGoForward }
            }
        ]
    }

    private func moved(to url: URL?) {
        guard let url, url != address else { return }
        address = url
        typed = url.absoluteString
        onNavigate()
    }
}

extension WebContent: WKUIDelegate {
    /// A link that asks for a new window opens in this page: there is no way from a page to a new tab yet.
    func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        if navigationAction.targetFrame == nil { webView.load(navigationAction.request) }
        return nil
    }
}
