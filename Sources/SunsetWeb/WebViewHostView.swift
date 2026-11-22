import AppKit
import WebKit

/// The view that holds a page's view in its pane (`WebViewHost`). It takes the page's view only once it has a size, and
/// lays it out at that size: a page shown again in a new host was given the host's zero size first, and for a turn its
/// scripts saw a 0 × 0 window, which a list that keeps only what is on screen (Slack's) reads as nothing to show; it came
/// back at its top (`Scripts/probes/webkit-rehost-scroll.swift`).
final class WebViewHostView: NSView {
    let webView: WKWebView

    /// The host each page belongs to: the newest made for it. A page can have two hosts for a moment (the split changed, a
    /// tab put in its own window); the older one never takes the page back. It did, at its next layout, from inside
    /// AppKit's layout pass, which throws (seen 2026-11-20, a test with the inspector docked).
    private static var owners: [ObjectIdentifier: WeakHost] = [:]

    private struct WeakHost {
        weak var host: WebViewHostView?
    }

    init(webView: WKWebView) {
        self.webView = webView
        super.init(frame: .zero)
        Self.owners[ObjectIdentifier(webView)] = WeakHost(host: self)
    }

    /// Whether this host is the page's: the newest made for it, or the only one left.
    var ownsPage: Bool {
        guard let owner = Self.owners[ObjectIdentifier(webView)]?.host, owner !== self else {
            Self.owners[ObjectIdentifier(webView)] = WeakHost(host: self)
            return true
        }
        return false
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

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
        // In full screen the view is WebKit's, in its own window; it gives it back when full screen ends.
        guard Self.takesBack(webView.fullscreenState) else { return }
        if webView.superview !== self {
            guard ownsPage else { return }
            // The inspector docked beside the page goes with it (the views WebKit added to the host it leaves).
            let inspector = (webView.superview as? WebViewHostView)?.subviews.filter { $0 !== webView } ?? []
            webView.removeFromSuperview()
            webView.autoresizingMask = []
            addSubview(webView)
            if !inspector.isEmpty {
                for view in inspector {
                    view.removeFromSuperview()
                    addSubview(view)
                }
                // Whole, then WebKit gives the inspector its side again (it lays both out when the page's frame changes).
                webView.frame = bounds
            }
        }
        // The inspector docked beside the page (WebKit's view, added here): WebKit sizes both. The page follows the pane by
        // its autoresizing, and its frame changing is what has WebKit lay both out again; set to the whole pane instead, it
        // went over the inspector at every layout, and WebKit took it back (a flicker, seen 2026-11-20).
        if isInspectorDocked {
            webView.autoresizingMask = [.width, .height]
            return
        }
        webView.autoresizingMask = []
        if webView.frame != bounds { webView.frame = bounds }
    }

    /// WebKit's inspector is docked in this pane: a view of its own beside the page's.
    var isInspectorDocked: Bool {
        subviews.contains { $0 !== webView }
    }

    override func didAddSubview(_ subview: NSView) {
        super.didAddSubview(subview)
        needsLayout = true
    }

    /// The inspector leaving gives the page the whole pane back.
    override func willRemoveSubview(_ subview: NSView) {
        super.willRemoveSubview(subview)
        needsLayout = true
    }

    /// Whether the host may hold the page's view: not while WebKit has it for full screen, going in, in, or coming out
    /// (taken back then, WebKit's full-screen window was left empty).
    static func takesBack(_ state: WKWebView.FullscreenState) -> Bool {
        state == .notInFullscreen
    }
}
