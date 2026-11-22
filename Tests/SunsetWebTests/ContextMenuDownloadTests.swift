import Foundation
import Testing
import WebKit

@testable import SunsetWeb
@testable import SunsetWebModel

/// "downloading image and video from their context menu options in pages does not work". WebKit's Download Image and
/// Download Video make the download themselves and hand it to the navigation delegate by a private method
/// (`_webView:contextMenuDidCreateDownload:`, asked of the navigation delegate: probed 2026-11-20); Sunset's must take it.
@MainActor @Suite("A download WebKit's page menu makes")
struct ContextMenuDownloadTests {
    @Test func `is taken into Sunset's downloads`() async throws {
        let server = try EchoServer(files: ["/red.png": ("image/png", MediaAddressTests.png)])
        let page = WebContent(url: nil, settings: WebSettings(applicationName: "Version/26.0 Safari/605.1.15"))
        page.setState(focused: true, visible: true)
        defer { page.stop() }
        let view = try #require(page.webView)
        let delegate = try #require(view.navigationDelegate as? NSObject)
        let selector = NSSelectorFromString("_webView:contextMenuDidCreateDownload:")
        #expect(delegate.responds(to: selector), "WebKit asks before handing it over: no answer, no download")
        let address = try #require(URL(string: "http://127.0.0.1:\(server.port)/red.png"))
        let download = await view.startDownload(using: URLRequest(url: address))
        defer { download.cancel() }
        if delegate.responds(to: selector) { _ = delegate.perform(selector, with: view, with: download) }
        #expect(DownloadCenter.shared.items.contains { $0.download === download })
    }
}
