import AppKit
import WebKit

/// The colour behind the page (`WKWebView.underPageBackgroundColor`, which WebKit derives from the page's own background): the
/// strip above a page that reaches the window's top is drawn in it, so that it reads as the page's and not as a black bar (owner
/// note n71).
extension WebContent {
    func observePageColor(_ view: WKWebView) -> NSKeyValueObservation {
        view.observe(\.underPageBackgroundColor, options: [.initial, .new]) { [weak self] view, _ in
            MainActor.assumeIsolated { self?.pageBackground = view.underPageBackgroundColor }
        }
    }
}
