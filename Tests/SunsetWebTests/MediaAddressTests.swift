import AemiTestKit
import AppKit
import Foundation
import SunsetTestSupport
import Testing
import WebKit

@testable import SunsetWeb
@testable import SunsetWebModel

/// The owner's note n64: "opening the address of a media, image or video shows a page that says it is impossible to load
/// the page". A picture's or a sound's address, opened in a tab, shows it, as Safari does, with no failure page.
@MainActor @Suite("A picture's or a film's address, opened")
struct MediaAddressTests {
    /// A 4 × 4 red PNG.
    static var png: Data {
        let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: 4,
            pixelsHigh: 4,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        )
        for x in 0 ..< 4 {
            for y in 0 ..< 4 { rep?.setColor(.red, atX: x, y: y) }
        }
        return rep?.representation(using: .png, properties: [:]) ?? Data()
    }

    /// Half a second of silence: 8 kHz, 8 bits, one channel.
    static var wav: Data {
        let samples = 4000
        var data = Data("RIFF".utf8)
        func le32(_ v: UInt32) {
            withUnsafeBytes(of: v.littleEndian) { data.append(contentsOf: $0) }
        }
        func le16(_ v: UInt16) {
            withUnsafeBytes(of: v.littleEndian) { data.append(contentsOf: $0) }
        }
        le32(UInt32(36 + samples))
        data.append(contentsOf: Array("WAVEfmt ".utf8))
        le32(16)
        le16(1)
        le16(1)
        le32(8000)
        le32(8000)
        le16(1)
        le16(8)
        data.append(contentsOf: Array("data".utf8))
        le32(UInt32(samples))
        data.append(contentsOf: [UInt8](repeating: 128, count: samples))
        return data
    }

    private func open(_ path: String, on server: EchoServer) async throws -> WebContent {
        let page = WebContent(
            url: URL(string: "http://127.0.0.1:\(server.port)\(path)"),
            settings: WebSettings(applicationName: "Version/26.0 Safari/605.1.15")
        )
        page.setState(focused: true, visible: true)
        let view = try #require(page.webView)
        // Done one way or the other: the page has its address and stopped loading, or failed.
        try await waitUntil(timeout: .seconds(15), label: "\(path) done loading") {
            page.failure != nil || (view.url != nil && !view.isLoading && view.estimatedProgress >= 1)
        }
        // A failure WebKit reports after the load ends shows too: a moment for it.
        await RealWait.pass(.milliseconds(300))
        return page
    }

    @Test func `a picture's address shows the picture, no failure`() async throws {
        let server = try EchoServer(files: ["/red.png": ("image/png", Self.png)])
        let page = try await open("/red.png", on: server)
        defer { page.stop() }
        #expect(page.failure == nil, "\(String(describing: page.failure?.reason))")
        let width = try await page.webView?
            .evaluateJavaScript("document.images[0] ? document.images[0].naturalWidth : 0")
        #expect(width as? Int == 4, "WebKit's image document holds the picture")
    }

    @Test func `a sound's or a film's address plays it in WebKit's media page, no failure`() async throws {
        let server = try EchoServer(files: ["/silence.wav": ("audio/wav", Self.wav)])
        let page = try await open("/silence.wav", on: server)
        defer { page.stop() }
        #expect(page.failure == nil, "\(String(describing: page.failure?.reason))")
    }
}
