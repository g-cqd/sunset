import AppKit
import SwiftUI
import WebKit

/// Holds the page's view, which outlives SwiftUI's views of it (a tab hidden and shown again keeps its page), and gives it the keyboard when its pane
/// has it.
struct WebViewHost: NSViewRepresentable {
    let webView: WKWebView
    let focused: Bool

    func makeNSView(context: Context) -> WebViewHostView {
        let host = WebViewHostView(webView: webView)
        host.place()
        return host
    }

    func updateNSView(_ host: WebViewHostView, context: Context) {
        host.place()
        guard focused, webView.superview === host, let window = host.window else { return }
        let responder = window.firstResponder as? NSView
        if responder == nil || !(responder?.isDescendant(of: webView) ?? false) { window.makeFirstResponder(webView) }
    }
}
