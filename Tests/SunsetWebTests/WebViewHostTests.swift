import AppKit
import Testing
import WebKit

@testable import SunsetWeb
@testable import SunsetWebModel

/// A list that keeps its place (Slack's conversations) came back at its top after a Space switch. A page shown again was put in a new host of no size first: for a turn
/// the page saw a 0 × 0 window (`Scripts/probes/webkit-rehost-scroll.swift`: a `resize` to 0x0), which a list that keeps only what is on screen, as Slack's, reads as
/// nothing to show.
@MainActor @Suite("A page's view put back in its pane")
struct WebViewHostTests {
    @Test func `a host of no size leaves the page at its size; once it has one, the page takes it`() {
        let view = WKWebView(frame: CGRect(x: 0, y: 0, width: 900, height: 700))
        let old = NSView(frame: view.frame)
        old.addSubview(view)
        let host = WebViewHostView(webView: view)
        host.setFrameSize(.zero)
        host.place()
        #expect(view.frame.size == CGSize(width: 900, height: 700), "never laid out at no size")
        host.setFrameSize(CGSize(width: 800, height: 600))
        #expect(view.superview === host && view.frame == CGRect(x: 0, y: 0, width: 800, height: 600))
    }
}
