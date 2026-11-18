import AppKit
import Foundation
import Testing
import WebKit

@testable import SunsetWeb

/// Roadmap 0022 W-c: the lists compiled are put on every page; a site's pause takes them off its pages; turned off, none.
@MainActor @Suite("Blocking on pages", .timeLimit(.minutes(1)))
struct ContentBlockerTests {
    /// The page has loaded: told by WebKit, not looked for.
    final class Loaded: NSObject, WKNavigationDelegate {
        var done: CheckedContinuation<Void, Never>?

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation?) {
            done?.resume()
            done = nil
        }
    }

    /// Whether the element `ad` of a page loaded in a new view, on `blocker` for `host`, is hidden.
    private func hidden(on blocker: ContentBlocker, host: String) async throws -> Bool {
        let view = WKWebView(frame: CGRect(x: 0, y: 0, width: 200, height: 100))
        let window = NSWindow(contentRect: view.frame, styleMask: [.borderless], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.contentView = view
        defer { window.close() }
        blocker.attach(view, host: host)
        let loaded = Loaded()
        view.navigationDelegate = loaded
        view.loadHTMLString("<div id='ad' class='banner'>ad</div>", baseURL: URL(string: "https://\(host)/"))
        await withCheckedContinuation { loaded.done = $0 }
        let display = try await view.evaluateJavaScript("getComputedStyle(document.getElementById('ad')).display")
        return (display as? String) == "none"
    }

    @Test func `a list hides what it names; a paused site and blocking off show it`() async throws {
        let folder = FileManager.default.temporaryDirectory.appending(path: "blocker-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: folder) }
        let blocker = ContentBlocker(folder: folder, pauses: BlockingPauses())
        await blocker.load([
            ContentBlocker.Source(
                address: "https://lists.example/a.txt",
                text: "##.banner\n||ads.example^",
                updated: .now
            )
        ])
        #expect(blocker.states.map(\.rules) == [2] && blocker.states.first?.problem == nil)
        #expect(try await hidden(on: blocker, host: "news.example"))
        blocker.pauses.set(true, for: "news.example")
        #expect(try await !hidden(on: blocker, host: "www.news.example"), "paused for the site")
        blocker.pauses.set(false, for: "news.example")
        blocker.enabled = false
        #expect(try await !hidden(on: blocker, host: "news.example"), "off")
    }

    @Test func `a pause is for the site and its subdomains, not a bare last label`() {
        let pauses = BlockingPauses()
        pauses.set(true, for: "www.Example.com")
        #expect(
            pauses.isPaused("example.com") && pauses.isPaused("shop.example.com") && !pauses.isPaused("example.org")
        )
        pauses.set(true, for: "com")
        #expect(!pauses.isPaused("other.com"))
    }
}
