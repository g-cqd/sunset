import AppKit
import Foundation
import Network
import Testing
import WebKit

@testable import SunsetWeb

/// Roadmap 0022 W-f, first form (the owner's note n75): a proxy set in Sunset carries the pages of every store. Probed with a
/// proxy on this Mac that answers every request itself: a page of a name that does not exist loads through it.
@MainActor @Suite("A proxy for the pages", .serialized, .timeLimit(.minutes(1)))
struct WebProxyTests {
    @Test func `addresses: http and socks5 with host and port; anything else is not a proxy`() {
        #expect(WebProxy("http://127.0.0.1:8080") == WebProxy(kind: .http, host: "127.0.0.1", port: 8080))
        #expect(WebProxy("socks5://proxy.example:1080") == WebProxy(kind: .socks, host: "proxy.example", port: 1080))
        #expect(WebProxy("https://proxy.example:443") == nil, "an https proxy is not one WebKit is given")
        #expect(WebProxy("http://proxy.example") == nil && WebProxy("") == nil && WebProxy("socks5://:1080") == nil)
    }

    final class Loaded: NSObject, WKNavigationDelegate {
        var done: CheckedContinuation<Bool, Never>?

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation?) { finish(true) }
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation?, withError error: any Error) {
            finish(false)
        }
        func webView(
            _ webView: WKWebView,
            didFailProvisionalNavigation navigation: WKNavigation?,
            withError error: any Error
        ) { finish(false) }

        private func finish(_ loaded: Bool) {
            done?.resume(returning: loaded)
            done = nil
        }
    }

    @Test func `a page of a name that does not exist loads through the proxy`() async throws {
        let proxy = try await AnsweringProxy.start()
        defer { proxy.stop() }
        let store = WKWebsiteDataStore.nonPersistent()
        WebProxy(kind: .http, host: "127.0.0.1", port: proxy.port).apply(to: store)
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = store
        let view = WKWebView(frame: CGRect(x: 0, y: 0, width: 300, height: 200), configuration: configuration)
        let window = NSWindow(contentRect: view.frame, styleMask: [.borderless], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.contentView = view
        defer { window.close() }
        let loaded = Loaded()
        view.navigationDelegate = loaded
        view.load(URLRequest(url: try #require(URL(string: "http://through-the-proxy.invalid/page"))))
        let ok = await withCheckedContinuation { loaded.done = $0 }
        #expect(ok)
        // Through a CONNECT tunnel to the name, then the request inside it.
        #expect(proxy.requests.first?.hasPrefix("CONNECT through-the-proxy.invalid:80") == true, "\(proxy.requests)")
        #expect(proxy.requests.contains { $0.hasPrefix("GET /page") })
        #expect(try await view.evaluateJavaScript("document.title") as? String == "proxied")
    }
}
