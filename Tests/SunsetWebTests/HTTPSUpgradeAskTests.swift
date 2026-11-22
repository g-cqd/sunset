import AemiTestKit
import Foundation
import SunsetTestSupport
import Testing
import WebKit

@testable import SunsetWeb
@testable import SunsetWebModel

/// Seen on screen 2026-11-20 with `web.httpsUpgrade` "ask": an http address typed in the field (a server on this
/// machine) loaded nothing, said nothing; the page stayed blank.
@MainActor @Suite("An http address with HTTPS asked first")
struct HTTPSUpgradeAskTests {
    @Test func `this machine's http page loads, or says why not`() async throws {
        let server = try EchoServer()
        var settings = WebSettings(applicationName: "Version/26.0 Safari/605.1.15")
        settings.httpsUpgrade = .ask
        let page = WebContent(url: nil, settings: settings)
        page.setState(focused: true, visible: true)
        defer { page.stop() }
        page.open(typed: "127.0.0.1:\(server.port)/here")
        let view = try #require(page.webView)
        let settled: Void? = try? await waitUntil(timeout: .seconds(10), label: "loaded or failed") {
            page.failure != nil || (view.url?.path == "/here" && !view.isLoading)
        }
        #expect(
            settled != nil,
            "neither: url \(String(describing: view.url)), loading \(view.isLoading), progress \(view.estimatedProgress), received \(server.received.count), failure \(String(describing: page.failure))"
        )
        #expect(server.header("User-Agent", for: "/here") != nil, "the server was asked")
    }
}
