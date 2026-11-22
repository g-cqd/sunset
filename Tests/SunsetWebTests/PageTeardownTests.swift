import AppKit
import Foundation
import Testing
import WebKit

@testable import SunsetWeb
@testable import SunsetWebModel

/// "closing a tab that had a video playing don't kill the video instantly". The cause: a page that stopped only let go of
/// its view, which played on while anything else held it (a host, the off-screen window). Probed (`/tmp/closeprobe`): let
/// go, it still played after 0.5 s; suspended, or closed, it did not. One way a page's view ends, for a tab closed, a page
/// unloaded, and Reload As.
@MainActor @Suite("A page's view, ended")
struct PageTeardownTests {
    @Test func `stopped, the view still held elsewhere is out of its window and its page closed`() {
        let page = WebContent(url: URL(string: "about:blank"), settings: WebSettings())
        page.makeLoadedForSharing()
        let held: WKWebView? = page.webView
        let host = NSView()
        if let held { host.addSubview(held) }
        page.stop()
        #expect(held?.superview == nil, "out of any window: nothing draws or plays it there")
        // Its page closed now (WebKit's own flag, read by name in this test only), not when the last holder lets go.
        #expect(held?.value(forKey: "_isClosed") as? Bool == true, "its page closed at once, whatever holds it")
    }
}
