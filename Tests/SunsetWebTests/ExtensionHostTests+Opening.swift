import AemiTestKit
import Foundation
import SunsetTestSupport
import Testing
import WebKit

@testable import SunsetWeb
@testable import SunsetWebModel

/// What an extension opens (`tabs.create`, a link in its popup, its options page) is opened by the app, in the extension's
/// profile. In `ExtensionHostTests`' suite: they share `ExtensionHosts.shared`, so they run one after another (run beside
/// it, a reset there made this fail, 2026-11-21).
extension ExtensionHostTests {
    /// WebKit asks the controller's delegate to open a tab (`tabs.create`, a link in a popup, the options page); Sunset
    /// answered nothing. The tab is opened by the app in the extension's profile, and the extension gets it back.
    @Test(.macOS27) func `an extension opens a tab`() async throws {
        let root = URL(filePath: NSTemporaryDirectory()).appending(path: "exthost-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: root) }
        let folder = root.appending(path: "src")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let manifest = #"""
            {"manifest_version": 3, "name": "Opener", "version": "1.0", "description": "A test.", "permissions": ["tabs"],
             "host_permissions": ["http://127.0.0.1/*"], "background": {"service_worker": "w.js"},
             "content_scripts": [{"matches": ["http://127.0.0.1/*"], "js": ["c.js"], "run_at": "document_end"}]}
            """#
        try Data(manifest.utf8).write(to: folder.appending(path: "manifest.json"))
        try Data(
            """
            chrome.runtime.onMessage.addListener((m, s, reply) => {
              chrome.tabs.create({ url: "https://example.com/opened", active: true })
                .then(tab => reply({ opened: tab ? tab.url ?? "no url" : "no tab" }))
                .catch(e => reply({ error: String(e) }));
              return true;
            });
            """
            .utf8
        )
        .write(to: folder.appending(path: "w.js"))
        try Data(Self.content.utf8).write(to: folder.appending(path: "c.js"))
        let profile = UUID()
        ExtensionHosts.shared.root = root.appending(path: "Extensions")
        defer { ExtensionHosts.shared.reset() }
        var asked: [URL?] = []
        var made: [WebContent] = []
        ExtensionHosts.shared.openTab = { url, _, _, _ in
            asked.append(url)
            var settings = WebSettings(applicationName: "Version/26.0 Safari/605.1.15")
            settings.profile = profile
            let page = WebContent(url: url, settings: settings)
            made.append(page)
            return page
        }
        defer { made.forEach { $0.stop() } }
        let host = try #require(ExtensionHosts.shared.host(for: profile))
        await host.ready()
        try await host.install(ExtensionHost.read(folder))
        let server = try EchoServer()
        var settings = WebSettings(applicationName: "Version/26.0 Safari/605.1.15")
        settings.profile = profile
        let page = WebContent(url: URL(string: "http://127.0.0.1:\(server.port)/shown"), settings: settings)
        let window = ExtensionWindow(profile: profile, isPrivate: false, pages: { [page] + made }, shown: { page })
        ExtensionHosts.shared.windows = { [window] }
        ExtensionHosts.shared.focused = { window }
        page.setState(focused: true, visible: true)
        ExtensionHosts.shared.sync()
        defer { page.stop() }
        let view = try #require(page.webView)
        var answer = "none"
        for _ in 0 ..< 80 where answer == "none" {
            await RealWait.pass(.milliseconds(100))
            answer =
                (try? await view.evaluateJavaScript("document.documentElement.dataset.worker ?? 'none'")) as? String
                ?? "none"
        }
        #expect(asked == [URL(string: "https://example.com/opened")], "\(answer)")
        #expect(answer.contains("opened"), "\(answer)")
    }
}
