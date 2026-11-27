import Foundation
import SunsetTestSupport
import SunsetWeb
import SunsetWebModel
import Testing

extension ExtensionHostTests {
    /// Seen 2026-11-21: uBlock Origin from Firefox injects a site's scriptlets once by hand, then leaves the later visits
    /// to `browser.contentScripts.register`, Firefox's content scripts from code, which WebKit has not: on a second visit
    /// no scriptlet ran. Sunset gives an extension that may read the page's address one, which runs the scripts once a
    /// matching page commits; a page that does not match runs none.
    @Test(.macOS27, arguments: ["/registered", "/elsewhere"])
    func `an extension's content scripts registered from code run on matching pages`(path: String) async throws {
        let root = URL(filePath: NSTemporaryDirectory()).appending(path: "exthost-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: root) }
        let folder = root.appending(path: "src")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let manifest = """
            {"manifest_version": 2, "name": "Registered", "version": "1.0", "description": "A test.",
             "permissions": ["webNavigation", "tabs", "http://127.0.0.1/*"], "background": {"scripts": ["b.js"]}}
            """
        try Data(manifest.utf8).write(to: folder.appending(path: "manifest.json"))
        let code = String(decoding: try JSONEncoder().encode(Self.content), as: UTF8.self)
        try Data(
            """
            let handle = null;
            const ready = browser.contentScripts.register({
              js: [{ code: \(code) }], matches: ["http://127.0.0.1/registered*"], runAt: "document_start", allFrames: true
            }).then(h => { handle = h; });
            browser.runtime.onMessage.addListener(async () => {
              await ready;
              return { unregister: typeof handle.unregister };
            });
            """
            .utf8
        )
        .write(to: folder.appending(path: "b.js"))
        let profile = UUID()
        ExtensionHosts.shared.root = root.appending(path: "Extensions")
        defer { ExtensionHosts.shared.reset() }
        let host = try #require(ExtensionHosts.shared.host(for: profile))
        await host.ready()
        try await host.install(ExtensionHost.read(folder))
        let server = try EchoServer()
        let found = try await dataset(of: path, private: false, profile: profile, port: server.port)
        if path == "/registered" {
            #expect(found["ext"] as? String == "ran")
            #expect(found["worker"] as? String == #"{"unregister":"function"}"#)
        } else {
            #expect(found["ext"] as? String == "none")
        }
    }
}
