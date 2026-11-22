import AppKit
import Foundation
import Testing
import WebKit

@testable import SunsetWeb
@testable import SunsetWebModel

/// An element picked on a page is hidden for good on its site (and its subdomains), whatever blocking says; the
/// selector names that element and no other.
@MainActor @Suite("Elements hidden for good", .timeLimit(.minutes(1)))
struct HiddenElementsTests {
    final class Loaded: NSObject, WKNavigationDelegate {
        var done: CheckedContinuation<Void, Never>?

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation?) {
            done?.resume()
            done = nil
        }
    }

    private static let page = """
        <body><div id="top">top</div><main><p>one</p><p class="x">two</p><section><p>three</p></section></main></body>
        """

    private func view(on blocker: ContentBlocker, host: String) async -> (WKWebView, NSWindow) {
        let view = WKWebView(frame: CGRect(x: 0, y: 0, width: 300, height: 200))
        let window = NSWindow(contentRect: view.frame, styleMask: [.borderless], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.contentView = view
        blocker.attach(view, host: host)
        let loaded = Loaded()
        view.navigationDelegate = loaded
        view.loadHTMLString(Self.page, baseURL: URL(string: "https://\(host)/"))
        await withCheckedContinuation { loaded.done = $0 }
        return (view, window)
    }

    @Test func `the selector names the element picked and no other`() async throws {
        let blocker = ContentBlocker(folder: FileManager.default.temporaryDirectory, pauses: BlockingPauses())
        let (view, window) = await view(on: blocker, host: "news.example")
        defer { window.close() }
        let second = try await ElementPicker.selector(of: "document.querySelectorAll('p')[1]", in: view)
        #expect(second == "body > main > p:nth-of-type(2)")
        #expect(try await ElementPicker.selector(of: "document.getElementById('top')", in: view) == "#top")
        let third = try await ElementPicker.selector(of: "document.querySelector('section p')", in: view)
        #expect(third == "body > main > section > p")
    }

    @Test func `a hidden element stays hidden on its site, with blocking off; not on another site`() async throws {
        let folder = FileManager.default.temporaryDirectory.appending(path: "hidden-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: folder) }
        let hidden = HiddenElements.make()
        let blocker = ContentBlocker(folder: folder, pauses: BlockingPauses(), hidden: hidden)
        blocker.enabled = false
        hidden.add("#top", for: "www.news.example")
        hidden.add("#top", for: "www.news.example")
        #expect(hidden.selectors(for: "news.example") == ["#top"], "once")
        await blocker.compileHidden()
        func display(_ view: WKWebView) async throws -> String? {
            try await view.evaluateJavaScript("getComputedStyle(document.getElementById('top')).display") as? String
        }
        let (on, first) = await view(on: blocker, host: "m.news.example")
        #expect(try await display(on) == "none")
        let (off, second) = await view(on: blocker, host: "other.example")
        #expect(try await display(off) == "block")
        first.close()
        second.close()
        hidden.remove("#top", for: "news.example")
        #expect(hidden.rules.isEmpty)
    }
}
