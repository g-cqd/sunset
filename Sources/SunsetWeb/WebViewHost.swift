import AppKit
import SwiftUI
import WebKit

/// Holds the page's view, which outlives SwiftUI's views of it (a tab hidden and shown again keeps its page), and gives it the keyboard when its pane
/// has it.
struct WebViewHost: NSViewRepresentable {
    let webView: WKWebView
    let focused: Bool

    func makeNSView(context: Context) -> NSView {
        let host = NSView()
        place(in: host)
        return host
    }

    func updateNSView(_ host: NSView, context: Context) {
        if webView.superview !== host { place(in: host) }
        guard focused, let window = host.window else { return }
        let responder = window.firstResponder as? NSView
        if responder == nil || !(responder?.isDescendant(of: webView) ?? false) { window.makeFirstResponder(webView) }
    }

    private func place(in host: NSView) {
        webView.removeFromSuperview()
        webView.frame = host.bounds
        webView.autoresizingMask = [.width, .height]
        host.addSubview(webView)
    }
}
