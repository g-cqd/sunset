import AppKit
import WebKit

/// The view that holds a page's view in its pane (`WebViewHost`). It takes the page's view only once it has a size, and
/// lays it out at that size: a page shown again in a new host was given the host's zero size first, and for a turn its
/// scripts saw a 0 × 0 window, which a list that keeps only what is on screen (Slack's) reads as nothing to show; it came
/// back at its top (roadmap 0047 A, `Scripts/probes/webkit-rehost-scroll.swift`).
final class WebViewHostView: NSView {
    let webView: WKWebView

    init(webView: WKWebView) {
        self.webView = webView
        super.init(frame: .zero)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        place()
    }

    override func layout() {
        super.layout()
        place()
    }

    /// Takes the page's view at this view's size; with no size yet, leaves it where it is, at its own.
    func place() {
        guard bounds.width > 0, bounds.height > 0 else { return }
        // In full screen the view is WebKit's, in its own window; it gives it back when full screen ends (n53).
        guard Self.takesBack(webView.fullscreenState) else { return }
        if webView.superview !== self {
            webView.removeFromSuperview()
            webView.autoresizingMask = []
            addSubview(webView)
        }
        if webView.frame != bounds { webView.frame = bounds }
    }

    /// Whether the host may hold the page's view: not while WebKit has it for full screen, going in, in, or coming out
    /// (taken back then, WebKit's full-screen window was left empty: the owner's note n53).
    static func takesBack(_ state: WKWebView.FullscreenState) -> Bool { state == .notInFullscreen }
}
