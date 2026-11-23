import AppKit
import WebKit

/// Where a page's view waits, with the inspector WebKit docked beside it, while no pane shows it (t339: its pane's host was
/// freed with the inspector's view in it, and the page, shown again, had lost its inspector and kept its room as a dark
/// band). One per page, kept while the page lives; the next host takes both from here.
@MainActor
enum WebViewParking {
    private static let spots = NSMapTable<WKWebView, NSView>.weakToStrongObjects()

    /// Moves `webView` and the views beside it in `host` (the docked inspector) to the page's spot.
    static func park(_ webView: WKWebView, from host: NSView) {
        guard webView.superview === host else { return }
        let spot = spots.object(forKey: webView) ?? NSView(frame: host.bounds)
        spot.frame = host.bounds
        spots.setObject(spot, forKey: webView)
        let beside = host.subviews.filter { $0 !== webView }
        let frame = webView.frame
        webView.removeFromSuperview()
        spot.addSubview(webView)
        webView.frame = frame
        for view in beside {
            let kept = view.frame
            view.removeFromSuperview()
            spot.addSubview(view)
            view.frame = kept
        }
    }

    /// Whether `view` is a page's spot.
    static func isSpot(_ view: NSView?) -> Bool {
        guard let view, let page = view.subviews.compactMap({ $0 as? WKWebView }).first else { return false }
        return spots.object(forKey: page) === view
    }
}
