import Foundation
import SunsetWeb
import SunsetWebModel
import Testing

extension ExtensionHostTests {
    /// Seen 2026-11-20 (diary 2026-11-20-19, W9): WebKit refuses a menu item whose `targetUrlPatterns` name a scheme of
    /// its own (uBlock Origin's "subscribe to this list" item, `abp:*` with an https pattern), so the item is not made
    /// and the call throws. Sunset drops the patterns WebKit refuses and keeps the others; an item left with none is not
    /// made (it would show on every link), and its id is given back as Firefox would.
    @Test
    func `a menu item with a pattern of another scheme is made with the patterns WebKit takes`() async throws {
        let root = URL(filePath: NSTemporaryDirectory()).appending(path: "exthost-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: root) }
        let folder = root.appending(path: "src")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let manifest = """
            {"manifest_version": 2, "name": "Menus", "version": "1.0", "description": "A test.",
             "permissions": ["menus", "http://127.0.0.1/*"], "background": {"scripts": ["b.js"]},
             "content_scripts": [{"matches": ["http://127.0.0.1/*"], "js": ["c.js"], "run_at": "document_end"}]}
            """
        try Data(manifest.utf8).write(to: folder.appending(path: "manifest.json"))
        try Data(
            """
            const make = (properties) => {
              try { return String(browser.menus.create(properties)); } catch (error) { return "threw " + error.message; }
            };
            const seen = {
              mixed: make({ id: "subscribe", title: "Subscribe", contexts: ["link"],
                            targetUrlPatterns: ["abp:*", "https://subscribe.adblockplus.org/*"] }),
              none: make({ id: "only-abp", title: "Only abp", contexts: ["link"], targetUrlPatterns: ["abp:*"] }),
              plain: make({ id: "plain", title: "Plain", contexts: ["page"] })
            };
            browser.runtime.onMessage.addListener(async () => seen);
            """
            .utf8
        )
        .write(to: folder.appending(path: "b.js"))
        try Data(Self.content.utf8).write(to: folder.appending(path: "c.js"))
        let profile = UUID()
        ExtensionHosts.shared.root = root.appending(path: "Extensions")
        defer { ExtensionHosts.shared.reset() }
        let host = try #require(ExtensionHosts.shared.host(for: profile))
        await host.ready()
        try await host.install(ExtensionHost.read(folder))
        let server = try EchoServer()
        let found = try await dataset(of: "/menus", private: false, profile: profile, port: server.port)
        let answer = try #require(found["worker"] as? String)
        for part in [#""mixed":"subscribe""#, #""none":"only-abp""#, #""plain":"plain""#] {
            #expect(answer.contains(part), "\(part) in \(answer)")
        }
    }
}
