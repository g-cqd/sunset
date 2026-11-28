package import Foundation
internal import SunsetRuntime
package import WebKit

/// What loads a page document into its web view (`LocalPageView`): first the file itself with the right to read its folder,
/// then the editor's text over it each time it changes, the scroll kept; the rules that keep it off the network; the watch
/// on its folder.
@MainActor package final class LocalPageLoader: NSObject, WKNavigationDelegate {
    /// What the view is to show.
    package struct Wanted: Equatable {
        var text: String
        var file: URL?
        var allowsNetwork: Bool
    }

    weak var view: WKWebView?
    var onLink: @MainActor (URL) -> Void
    private var shown: Wanted?
    /// The folder the page was given the right to read, and the watch on it.
    private var folder: URL?
    private var watch: (any DispatchSourceFileSystemObject)?
    /// Where it was scrolled to, put back once the text is drawn again.
    private var scroll: String?
    private static var offline: WKContentRuleList?

    /// Everything but files (the folder is all the page may read), data and the page itself is blocked. A filter has no
    /// alternatives (`|`): one rule a scheme.
    private static let offlineRules =
        "[{\"trigger\":{\"url-filter\":\".*\"},\"action\":{\"type\":\"block\"}}"
        + ["file", "data", "blob", "about"]
        .map { ",{\"trigger\":{\"url-filter\":\"^\($0):\"},\"action\":{\"type\":\"ignore-previous-rules\"}}" }
        .joined() + "]"

    init(onLink: @escaping @MainActor (URL) -> Void) {
        self.onLink = onLink
    }

    func show(_ wanted: Wanted) {
        guard wanted != shown, let view else { return }
        let before = shown
        shown = wanted
        guard wanted.allowsNetwork || Self.offline != nil else {
            // The rules are compiled once, then the page is loaded under them.
            Runtime.live.task { @MainActor [weak self] in
                Self.offline = try? await WKContentRuleListStore.default()
                    .compileContentRuleList(
                        forIdentifier: "sunset-local-page",
                        encodedContentRuleList: Self.offlineRules
                    )
                guard Self.offline != nil, let self, let wanted = self.shown else { return }
                self.shown = before
                self.show(wanted)
            }
            return
        }
        let rules = view.configuration.userContentController
        rules.removeAllContentRuleLists()
        if !wanted.allowsNetwork, let offline = Self.offline { rules.add(offline) }
        guard let file = wanted.file else {
            return reload(wanted.text, base: nil)
        }
        let directory = file.deletingLastPathComponent()
        guard folder == directory else {
            // First the file as it is on disk, which gives the page its folder; the text over it once it differs.
            folder = directory
            watchFolder(directory)
            ownLoad = true
            view.loadFileURL(file, allowingReadAccessTo: directory)
            if (try? String(contentsOf: file, encoding: .utf8)) != wanted.text { pendingText = true }
            return
        }
        reload(wanted.text, base: file)
    }

    /// The text is to be drawn once the file is.
    private var pendingText = false
    /// The next load of the page is this loader's (the file, the text), not one the page asks for.
    private var ownLoad = false

    /// The text drawn again where it is scrolled to.
    private func reload(_ text: String, base: URL?) {
        guard let view else { return }
        view.evaluateJavaScript("[window.scrollX, window.scrollY].join(',')") { [weak self] value, _ in
            MainActor.assumeIsolated {
                self?.scroll = value as? String
                self?.ownLoad = true
                _ = self?.view?.loadHTMLString(text, baseURL: base)
            }
        }
    }

    private func watchFolder(_ directory: URL) {
        watch?.cancel()
        let descriptor = unsafe open(directory.path, O_EVTONLY)
        guard descriptor >= 0 else { return }
        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: descriptor,
            eventMask: [.write, .rename, .link],
            queue: .main
        )
        source.setEventHandler { [weak self] in
            MainActor.assumeIsolated { self?.folderChanged() }
        }
        source.setCancelHandler { close(descriptor) }
        source.resume()
        watch = source
    }

    /// A file of the folder was saved: the page drawn again, its styles and scripts read anew.
    private func folderChanged() {
        guard let view, view.url != nil else { return }
        view.reloadFromOrigin()
    }

    func stop() {
        watch?.cancel()
        watch = nil
        view?.stopLoading()
    }

    // MARK: WKNavigationDelegate

    package func webView(
        _ webView: WKWebView,
        decidePolicyFor action: WKNavigationAction
    ) async -> WKNavigationActionPolicy {
        // This loader's loads, a reload, a frame inside the page and a jump within it stay; anything else the page goes to
        // (a link, a script) is Sunset's to open: a file as a document, a page in a tab.
        guard action.targetFrame?.isMainFrame != false, action.navigationType != .reload, let url = action.request.url
        else { return .allow }
        if ownLoad {
            ownLoad = false
            return .allow
        }
        if let here = webView.url, url.fragment != nil, Self.sameDocument(url, here) { return .allow }
        onLink(url)
        return .cancel
    }

    package func webView(_ webView: WKWebView, didFinish navigation: WKNavigation?) {
        if pendingText, let shown {
            pendingText = false
            return reload(shown.text, base: shown.file)
        }
        guard let scroll else { return }
        self.scroll = nil
        webView.evaluateJavaScript("window.scrollTo(\(scroll))")
    }

    /// The same page but for the fragment.
    static func sameDocument(_ first: URL, _ second: URL) -> Bool {
        func base(_ url: URL) -> String {
            url.absoluteString.split(separator: "#", maxSplits: 1).first.map(String.init) ?? url.absoluteString
        }
        return base(first) == base(second)
    }
}
