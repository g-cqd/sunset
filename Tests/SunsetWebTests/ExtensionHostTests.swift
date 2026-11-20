import AemiTestKit
import Foundation
import SunsetTestSupport
import Testing
import WebKit

@testable import SunsetWeb
@testable import SunsetWebModel

/// Roadmap 0109 B: a page of a profile runs that profile's extensions: the content script on a page it was granted, its worker
/// answering it (WebKit needs the page as a tab: probed, diary 2026-11-20-13). Not in a private page unless allowed there.
@MainActor @Suite("A profile's extensions in its pages", .serialized, .timeLimit(.minutes(1)))
struct ExtensionHostTests {
    static let content = """
        document.documentElement.dataset.ext = "ran";
        chrome.runtime.sendMessage({ hi: true }).then(a => { document.documentElement.dataset.worker = JSON.stringify(a); });
        """
    static let worker = """
        chrome.runtime.onMessage.addListener((m, s, reply) => { reply({ from: "worker" }); return true; });
        """

    private func installHello(in root: URL, profile: UUID) throws {
        let folder = root.appending(path: "src")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let manifest = #"""
            {"manifest_version": 3, "name": "Hello", "version": "1.0", "description": "A test.",
             "host_permissions": ["http://127.0.0.1/*"], "background": {"service_worker": "w.js"},
             "content_scripts": [{"matches": ["http://127.0.0.1/*"], "js": ["c.js"], "run_at": "document_end"}]}
            """#
        try Data(manifest.utf8).write(to: folder.appending(path: "manifest.json"))
        try Data(Self.content.utf8).write(to: folder.appending(path: "c.js"))
        try Data(Self.worker.utf8).write(to: folder.appending(path: "w.js"))
        var store = ExtensionStore(root: root.appending(path: "Extensions"), profile: profile)
        try store.install(from: folder, name: "Hello", granted: ["http://127.0.0.1/*"])
    }

    private func dataset(of path: String, private isPrivate: Bool, profile: UUID, port: UInt16) async throws -> [String:
        Any]
    {
        var settings = WebSettings(applicationName: "Version/26.0 Safari/605.1.15")
        settings.profile = profile
        if isPrivate { settings.privacy = PagePrivacy() }
        let page = WebContent(url: URL(string: "http://127.0.0.1:\(port)\(path)"), settings: settings)
        page.setState(focused: true, visible: true)
        defer { page.stop() }
        let view = try #require(page.webView)
        try await waitUntil(timeout: .seconds(10), label: "loaded") { !view.isLoading && view.url?.path == path }
        // The worker's answer comes after the script; when the script did not run, none comes: three seconds at most.
        let read =
            "({ ext: document.documentElement.dataset.ext ?? 'none', worker: document.documentElement.dataset.worker ?? 'none' })"
        var found = try await view.evaluateJavaScript(read)
        for _ in 0 ..< 30 where (found as? [String: Any])?["worker"] as? String == "none" {
            await RealWait.pass(.milliseconds(100))
            found = try await view.evaluateJavaScript(read)
        }
        return try #require(found as? [String: Any])
    }

    @Test func `a profile's page runs its extension; a private page does not until allowed`() async throws {
        let root = URL(filePath: NSTemporaryDirectory()).appending(path: "exthost-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: root) }
        let profile = UUID()
        try installHello(in: root, profile: profile)
        ExtensionHosts.shared.root = root.appending(path: "Extensions")
        defer { ExtensionHosts.shared.reset() }
        await ExtensionHosts.shared.host(for: profile)?.ready()
        let server = try EchoServer()
        let shown = try await dataset(of: "/a", private: false, profile: profile, port: server.port)
        #expect(shown["ext"] as? String == "ran")
        #expect((shown["worker"] as? String)?.contains("worker") == true, "\(shown)")
        let hidden = try await dataset(of: "/b", private: true, profile: profile, port: server.port)
        #expect(hidden["ext"] as? String == "none", "private, not allowed there")
    }
}
