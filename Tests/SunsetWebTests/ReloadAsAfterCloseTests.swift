import AemiTestKit
import AppKit
import Foundation
import SunsetTestSupport
import Testing
import WebKit

@testable import SunsetWeb
@testable import SunsetWebModel

/// The owner (2026-11-23, t338): a favorite loaded as a profile removed, a new tab on the same address reloaded as that
/// profile showed black. A page as profile P ended; another reloaded as P while shown: it draws its page.
@MainActor @Suite("Reload As after a page of that profile ended", .serialized, .timeLimit(.minutes(1)))
struct ReloadAsAfterCloseTests {
    private func window(_ view: WKWebView) -> NSWindow {
        view.frame = CGRect(x: 0, y: 0, width: 300, height: 200)
        let window = NSWindow(contentRect: view.frame, styleMask: [.borderless], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.contentView = view
        return window
    }

    /// Whether the view draws the page's red (not black, not blank).
    private func drawsRed(_ view: WKWebView) async -> Bool {
        let configuration = WKSnapshotConfiguration()
        configuration.rect = CGRect(x: 10, y: 10, width: 20, height: 20)
        guard let image = try? await view.takeSnapshot(configuration: configuration),
            let cg = image.cgImage(forProposedRect: nil, context: nil, hints: nil)
        else { return false }
        let rep = NSBitmapImageRep(cgImage: cg)
        guard let colour = rep.colorAt(x: 5, y: 5)?.usingColorSpace(.sRGB) else { return false }
        return colour.redComponent > 0.8 && colour.greenComponent < 0.2
    }

    @Test(.macOS27) func `the new page draws, not black`() async throws {
        let profile = UUID()
        let server = try EchoServer(pages: ["/": "<body style='background:#f00;margin:0'>red</body>"])
        let address = try #require(URL(string: "http://127.0.0.1:\(server.port)/"))
        var settings = WebSettings(applicationName: "Version/26.0 Safari/605.1.15")
        settings.profile = profile
        let favorite = WebContent(url: address, settings: settings)
        favorite.setState(focused: true, visible: true)
        let first = window(try #require(favorite.webView))
        try await waitUntil(timeout: .seconds(15), label: "the favorite drew") {
            await drawsRed(try #require(favorite.webView))
        }
        first.close()
        favorite.stop()
        settings.profile = nil
        let tab = WebContent(url: address, settings: settings)
        tab.setState(focused: true, visible: true)
        let second = window(try #require(tab.webView))
        defer { second.close() }
        try await waitUntil(timeout: .seconds(15), label: "the tab drew") { await drawsRed(try #require(tab.webView)) }
        tab.reload(as: profile)
        let remade = try #require(tab.webView)
        second.contentView = remade
        remade.frame = CGRect(x: 0, y: 0, width: 300, height: 200)
        try await waitUntil(timeout: .seconds(15), label: "reloaded as the profile, it draws") {
            await drawsRed(remade)
        }
        tab.stop()
        try? await WKWebsiteDataStore.remove(forIdentifier: profile)
    }
}
