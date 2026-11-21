import AemiTestKit
import Foundation
import SunsetTestSupport
import Testing
import WebKit

@testable import SunsetWeb
@testable import SunsetWebModel

/// The owner, 2026-11-21: "it seems sunset refuses to open webkit-extension url scheme". WebKit shows an extension's page as a
/// page of its own only in a web view made from the extension's configuration (it carries the extension's base URL);
/// in a tab's ordinary one it fails ("resource unavailable", -1008). A tab whose address is an extension's page gets one,
/// and a new view each time it crosses between the extension's pages and the web.
extension ExtensionHostTests {
    @Test func `an extension's page opens in a tab, and from a web page`() async throws {
        let root = URL(filePath: NSTemporaryDirectory()).appending(path: "extpage-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: root) }
        let folder = root.appending(path: "src")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let manifest =
            #"{"manifest_version": 3, "name": "Pages", "version": "1.0", "description": "A test.", "options_page": "o.html"}"#
        try Data(manifest.utf8).write(to: folder.appending(path: "manifest.json"))
        try Data("<!doctype html><title>Options of Pages</title>o".utf8).write(to: folder.appending(path: "o.html"))
        ExtensionHosts.shared.root = root.appending(path: "Extensions")
        defer { ExtensionHosts.shared.reset() }
        let profile = UUID()
        let host = try #require(ExtensionHosts.shared.host(for: profile))
        await host.ready()
        let entry = try await host.install(ExtensionHost.read(folder))
        let options = try #require(URL(string: "webkit-extension://\(entry.id.uuidString.lowercased())/o.html"))

        var settings = WebSettings(applicationName: "Version/26.0 Safari/605.1.15")
        settings.profile = profile
        let page = WebContent(url: options, settings: settings)
        defer { page.stop() }
        page.setState(focused: true, visible: true)
        try await waitUntil(timeout: .seconds(10), label: "the options page") {
            page.webView?.title == "Options of Pages" || page.failure != nil
        }
        #expect(page.failure == nil, "\(String(describing: page.failure))")
        #expect(page.webView?.title == "Options of Pages")

        // From the web to the extension's page, in the same tab.
        let server = try EchoServer()
        page.load(try #require(URL(string: "http://127.0.0.1:\(server.port)/web")))
        try await waitUntil(timeout: .seconds(10), label: "the web page") { page.webView?.url?.scheme == "http" }
        page.load(options)
        try await waitUntil(timeout: .seconds(10), label: "the options page again") {
            page.webView?.title == "Options of Pages" || page.failure != nil
        }
        #expect(page.failure == nil, "\(String(describing: page.failure))")
        #expect(page.webView?.url == options)
    }

    /// At launch the shown tab is made before the profile's extensions have loaded (seen 2026-11-21: an extension's page
    /// restored from the session failed, "-1008"): it waits for them, then opens.
    @Test func `an extension's page restored at launch opens once its extension has loaded`() async throws {
        let root = URL(filePath: NSTemporaryDirectory()).appending(path: "extpage-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: root) }
        let folder = root.appending(path: "src")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let manifest =
            #"{"manifest_version": 3, "name": "Pages", "version": "1.0", "description": "A test.", "options_page": "o.html"}"#
        try Data(manifest.utf8).write(to: folder.appending(path: "manifest.json"))
        try Data("<!doctype html><title>Options of Pages</title>o".utf8).write(to: folder.appending(path: "o.html"))
        ExtensionHosts.shared.root = root.appending(path: "Extensions")
        defer { ExtensionHosts.shared.reset() }
        let profile = UUID()
        let first = try #require(ExtensionHosts.shared.host(for: profile))
        await first.ready()
        let entry = try await first.install(ExtensionHost.read(folder))
        let options = try #require(URL(string: "webkit-extension://\(entry.id.uuidString.lowercased())/o.html"))

        // The next launch: the page shown at once, its extensions not loaded yet.
        ExtensionHosts.shared.reset()
        ExtensionHosts.shared.root = root.appending(path: "Extensions")
        var settings = WebSettings(applicationName: "Version/26.0 Safari/605.1.15")
        settings.profile = profile
        let page = WebContent(url: options, settings: settings)
        defer { page.stop() }
        page.setState(focused: true, visible: true)
        try await waitUntil(timeout: .seconds(10), label: "the options page") {
            page.webView?.title == "Options of Pages" || page.failure != nil
        }
        #expect(page.failure == nil, "\(String(describing: page.failure))")
        #expect(page.webView?.title == "Options of Pages")
    }
}
