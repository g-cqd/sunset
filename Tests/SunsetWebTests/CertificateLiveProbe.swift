import AppKit
import Foundation
import SunsetTestSupport
import Testing
import WebKit

@testable import SunsetWeb
@testable import SunsetWebModel

/// By hand (SUNSET_CERT_PROBE=1, the network): a real certificate failure from WebKit carries the certificate shown.
@MainActor @Suite("certificate probe", .enabled(if: ProcessInfo.processInfo.environment["SUNSET_CERT_PROBE"] != nil))
struct CertificateLiveProbe {
    @Test func `self-signed`() async throws {
        let page = WebContent(
            url: URL(string: "https://self-signed.badssl.com/"),
            settings: WebSettings(applicationName: "x")
        )
        page.setState(focused: true, visible: true)
        defer { page.stop() }
        let view = try #require(page.webView)
        view.frame = CGRect(x: 0, y: 0, width: 400, height: 300)
        let window = NSWindow(contentRect: view.frame, styleMask: [.borderless], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.contentView = view
        defer { window.close() }
        view.load(URLRequest(url: try #require(URL(string: "https://self-signed.badssl.com/"))))
        for _ in 0 ..< 100 where page.failure == nil { await RealWait.pass(.milliseconds(100)) }
        print(
            "CERT failure:",
            page.failure?.isCertificate as Any,
            "certificate:",
            page.failure?.certificate?.count as Any
        )
    }
}
